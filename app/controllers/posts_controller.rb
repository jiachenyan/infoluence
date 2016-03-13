class PostsController < ApplicationController
	before_action :signed_in_user, only: [:create, :share_post]

	POSTS_PER_PAGE = 20

	def create
		post = current_user.posts.new
		post.content = params[:content]

		return render json_error(post) unless post.save

		@influence = post.influences.new
		@influence.inf_type = 'oc'
		@influence.user_id = post.user_id
		return render json_error(@influence) unless @influence.save

		# update stats
		ActiveRecord::Base.connection.execute(<<-SQL.squish
			UPDATE users SET total_posts = total_posts+1
			WHERE id = #{post.user.id};
			COMMIT;
		SQL
		)

		# TODO: add to post_links (low pri, for data purposes)

		render jsonize(serialize_inf)
	end

	def send_post
		inf_id = params[:inf_id]
		@influence = Influence.includes(:post).find_by_id(inf_id)
		return render json_error('Invalid id') unless @influence.present?
		@post = @influence.post
		return render json_error('Invalid id') unless @post.present?
		
		# update stats
		user_id = current_user.try(:id) || 'NULL'
		time = Time.now.utc.iso8601(10)
		ActiveRecord::Base.connection.execute(<<-SQL.squish
			BEGIN;
			INSERT INTO influences (
				inf_type, user_id, post_id, from_inf_id, created_at, updated_at
			)
			VALUES (
				'rd', #{user_id}, #{@post.id}, #{inf_id}, '#{time}', '#{time}'
			);

			UPDATE posts SET total_reads = total_reads+1
			WHERE id = #{@post.id};

			UPDATE users SET total_read_influence = total_read_influence+1
			WHERE id = #{@post.user.id};
			COMMIT;
		SQL
		)

		render jsonize(serialize_inf)
	end

	def share_post
		from_inf_id = params[:from_inf_id]
		from_influence = Influence.includes(:post).find_by_id(from_inf_id)
		return render json_error('Invalid id') unless from_influence.present?
		post = from_influence.post
		return render json_error('Invalid id') unless post.present?

		@influence = Influence.new
		@influence.inf_type = 'sh'
		@influence.user_id = current_user.id
		@influence.post_id = post.id
		@influence.from_inf_id = from_inf_id

		if @influence.save
			ActiveRecord::Base.connection.execute(<<-SQL.squish
				BEGIN;
				UPDATE posts SET total_shares = total_shares+1
				WHERE id = #{post.id};

				UPDATE users SET total_share_influence = total_share_influence+1
				WHERE id = #{post.user.id};

				UPDATE users SET total_shares = total_shares+1
				WHERE id = #{current_user.id};
				COMMIT;
			SQL
			)
			render jsonize(serialize_inf)
		else
			render json_error(@influence)
		end
	end

	def send_timeline
		infs_query_init

		@infs_query_ast = @infs_query_ast
		.where(
			@infs_tb[:inf_type].eq('oc')
			.or(
				@infs_tb[:inf_type].eq('sh')
			)
		)
		.order(@infs_tb[:created_at].desc)
		@infs_query_ast = paginate(@infs_query_ast, params[:page], POSTS_PER_PAGE)

		render jsonize(json_agg_exec(infs_query))
	end

	def send_follow_timeline
		infs_query_init

		render jsonize(json_agg_exec(infs_query))
	end

	private

	# for create, send_post and share_post
	def serialize_inf
		infs_query_init

		@infs_query_ast.where(
			@infs_tb[:id].eq(@influence.id)
		).take(1)

		json_agg_exec(infs_query).first
	end

	def infs_query_init
		@infs_tb = Influence.arel_table
		@infs_query_ast = @infs_tb
		.project(
			@infs_tb[:id].as('"infId"'),
			@infs_tb[:inf_type].as('"infType"'),
			@infs_tb[:user_id],
			@infs_tb[:post_id],
			@infs_tb[:from_inf_id],
			arel_sql_epoch(@infs_tb, :created_at, :publishTime)
		)
	end

	def infs_query
		@infs_cte = Arel::Table.new(:infs_cte)
		@infs_cte_as = Arel::Nodes::As.new(@infs_cte, @infs_query_ast)


		# posts
		@post_tb = Post.arel_table
		@posts_query_ast = @post_tb.project(
			@post_tb[:id],
			@post_tb[:user_id],
			@post_tb[:content],
			@post_tb[:total_reads].as('"totalReads"'),
			@post_tb[:total_shares].as('"totalShares"'),
			arel_sql_epoch(@post_tb, :created_at, :createTime)
		)
		.where(
			@post_tb[:id].in(
				@infs_cte.project(@infs_cte[:post_id])
			)
		)
		@posts_cte = Arel::Table.new(:posts_cte)
		@posts_cte_as = Arel::Nodes::As.new(@posts_cte, @posts_query_ast)


		# users -> authors, publishers
		@users_tb = User.arel_table
		@users_query_ast = @users_tb.project(
			@users_tb[:id],

			json_build_object(
				Arel.sql("'name'"), @users_tb[:name],
				Arel.sql("'username'"), @users_tb[:username],
				Arel.sql("'avatarThumb'"), avatar_url_attr(:thumb),
				Arel.sql("'avatarMedium'"), avatar_url_attr(:medium),

				Arel.sql("'totalRdInf'"), @users_tb[:total_read_influence],
				Arel.sql("'totalShInf'"), @users_tb[:total_share_influence],

				Arel.sql("'totalShares'"), @users_tb[:total_shares],
				Arel.sql("'totalPosts'"), @users_tb[:total_posts],
				Arel.sql("'regTime'"), arel_sql_epoch(@users_tb, :created_at)
			).as('user_data')
		)

		@authors_query_ast = @users_query_ast.dup
		.where(
			@users_tb[:id].in(
				@posts_cte.project(@posts_cte[:user_id])
			)
		)
		@authors_cte = Arel::Table.new(:authors_cte)
		@authors_cte_as = Arel::Nodes::As.new(@authors_cte, @authors_query_ast)

		@publishers_query_ast = @users_query_ast.dup
		.where(
			@users_tb[:id].in(
				@infs_cte.project(@infs_cte[:user_id])
			)
		)
		@publishers_cte = Arel::Table.new(:publishers_cte)
		@publishers_cte_as = Arel::Nodes::As.new(@publishers_cte, @publishers_query_ast)


		# data
		@inf_data_query_ast = @infs_tb.project(
			@infs_tb[:post_id],
			json_agg(json_build_array(
				@infs_tb[:id],
				@infs_tb[:inf_type],
				@infs_tb[:from_inf_id]
			)).as('"graphData"')
		)
		.where(
			@infs_tb[:post_id].in(
				@infs_cte.project(@infs_cte[:post_id])
			)
		)
		.group(@infs_tb[:post_id])

		@inf_data_cte = Arel::Table.new(:inf_data_cte)
		@inf_data_cte_as = Arel::Nodes::As.new(@inf_data_cte, @inf_data_query_ast)


		# query
		@infs_query_ast = @infs_cte.project(
			@infs_cte[:infId],
			@infs_cte[:infType],
			@infs_cte[:publishTime],

			@posts_cte[:content],
			@posts_cte[:totalReads],
			@posts_cte[:totalShares],
			@posts_cte[:createTime],

			@authors_cte[:user_data].as('"author"'),
			@publishers_cte[:user_data].as('"publisher"'),

			@inf_data_cte[:graphData]
		)
		.join(@posts_cte, Arel::Nodes::OuterJoin)
		.on(
			@infs_cte[:post_id].eq(@posts_cte[:id])
		)
		.join(@authors_cte, Arel::Nodes::OuterJoin)
		.on(
			@posts_cte[:user_id].eq(@authors_cte[:id])
		)
		.join(@publishers_cte, Arel::Nodes::OuterJoin)
		.on(
			@infs_cte[:user_id].eq(@publishers_cte[:id])
		)
		.join(@inf_data_cte, Arel::Nodes::OuterJoin)
		.on(
			@infs_cte[:post_id].eq(@inf_data_cte[:post_id])
		)
		.order(
			@infs_cte[:publishTime].desc
		)
		.with(
			@infs_cte_as,
			@posts_cte_as,
			@authors_cte_as,
			@publishers_cte_as,
			@inf_data_cte_as
		)
	end
end
