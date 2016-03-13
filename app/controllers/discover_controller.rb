class DiscoverController < ApplicationController
	SEARCH_ITEMS_PER_PAGE = 10

	def search_all
		query = ActiveRecord::Base.sanitize((params[:q] || ''))
		tsquery = ActiveRecord::Base.sanitize((params[:q] || '').gsub(/\s/, ':* & ') << ':*')
		page = params[:p] || 1

		@users_tb = User.arel_table
		@urels_tb = UserRelationship.arel_table

		@users_search_query_ast = @users_tb
		.project(
			@users_tb[:name],
			@users_tb[:username],
			avatar_url_attr(:thumb, :avatarThumb),
			avatar_url_attr(:medium, :avatarMedium),
			Arel.sql('"users"."properties" -> \'info\'').as('"userInfo"'),

			@users_tb[:total_read_influence].as('"totalRdInf"'),
			@users_tb[:total_share_influence].as('"totalShInf"'),
			@users_tb[:total_shares].as('"totalShares"'),
			@users_tb[:total_posts].as('"totalPosts"'),

			Arel.sql(<<-SQL.squish
				CASE WHEN #{current_user.try(:id) || 'NULL'} IS NULL THEN
					NULL
				WHEN "user_relationships"."id" IS NOT NULL THEN
					TRUE
				ELSE
					FALSE
				END
			SQL
			).as('"followStatus"'),

			Arel.sql(<<-SQL.squish
				SIMILARITY("users"."username", #{query}) + 
				SIMILARITY("users"."name", #{query})
			SQL
			).as('"relv_score"')
		)
		.join(@urels_tb, Arel::Nodes::OuterJoin)
		.on(
			@users_tb[:id].eq(@urels_tb[:follows_id])
			.and(@urels_tb[:follower_id].eq(current_user.try(:id)))
		)
		.where(
			Arel.sql(<<-SQL.squish
				"users"."username" % #{query}
				OR
				"users"."name" % #{query}
			SQL
			)
		)
		.order(
			Arel.sql('"relv_score"').desc
		)

		@users_search_query_ast = paginate(@users_search_query_ast, page, SEARCH_ITEMS_PER_PAGE)

		@users_search_cte = Arel::Table.new(:users_cte)
		@users_search_cte_as = Arel::Nodes::As.new(@users_search_cte, @users_search_query_ast)

		# agg user search
		@users_agg_query = Arel.sql(<<-SQL.squish
			(SELECT JSON_AGG("users_agg") AS "users_agg"
			FROM (#{
				@users_search_cte.project(
					@users_search_cte[:name],
					@users_search_cte[:username],
					@users_search_cte[:avatarThumb],
					@users_search_cte[:avatarMedium],
					@users_search_cte[:userInfo],
					@users_search_cte[:totalRdInf],
					@users_search_cte[:totalShInf],
					@users_search_cte[:totalShares],
					@users_search_cte[:totalPosts],
					@users_search_cte[:followStatus]
				).to_sql
			}) AS "users_agg")
		SQL
		)

		@users_agg_cte = Arel::Table.new(:users_agg_cte)
		@users_agg_cte_as = Arel::Nodes::As.new(@users_agg_cte, @users_agg_query)


		# posts
		@post_tb = Post.arel_table
		@posts_search_query_ast = @post_tb.project(
			@post_tb[:id],
			@post_tb[:user_id],
			@post_tb[:content],
			@post_tb[:total_reads].as('"totalReads"'),
			@post_tb[:total_shares].as('"totalShares"'),
			arel_sql_epoch(@post_tb, :created_at, :createTime)
		)
		.where(
			Arel.sql(<<-SQL.squish
				to_tsvector('english', "posts"."content" ->> 'title') @@ to_tsquery(#{tsquery})
			SQL
			)
		)

		@posts_search_query_ast = paginate(@posts_search_query_ast, page, SEARCH_ITEMS_PER_PAGE)

		@posts_search_cte = Arel::Table.new(:posts_search_cte)
		@posts_search_cte_as = Arel::Nodes::As.new(@posts_search_cte, @posts_search_query_ast)

		# infs search
		@infs_tb = Influence.arel_table
		@infs_search_query_ast = @infs_tb
		.project(
			@infs_tb[:id].as('"infId"'),
			@infs_tb[:inf_type].as('"infType"'),
			@infs_tb[:user_id],
			@infs_tb[:post_id],
			@infs_tb[:from_inf_id],
			arel_sql_epoch(@infs_tb, :created_at, :publishTime),

			@posts_search_cte[:content],
			@posts_search_cte[:totalReads],
			@posts_search_cte[:totalShares],
			@posts_search_cte[:createTime],
			@posts_search_cte[:user_id].as('"author_id"')
		)
		.join(@posts_search_cte)
		.on(
			@infs_tb[:post_id].eq(@posts_search_cte[:id])
			.and(@infs_tb[:inf_type].eq('oc'))
		)

		@infs_search_cte = Arel::Table.new(:infs_search_cte)
		@infs_search_cte_as = Arel::Nodes::As.new(@infs_search_cte, @infs_search_query_ast)


		# users -> authors, publishers, follow status
		@users_query_ast = @users_tb.project(
			@users_tb[:id],
			json_build_object(
				Arel.sql("'name'"), @users_tb[:name],
				Arel.sql("'username'"), @users_tb[:username],
				Arel.sql("'avatarThumb'"), avatar_url_attr(:thumb),
				Arel.sql("'avatarMedium'"), avatar_url_attr(:medium),
				Arel.sql("'userInfo'"), Arel.sql('"users"."properties" -> \'info\''),

				Arel.sql("'totalRdInf'"), @users_tb[:total_read_influence],
				Arel.sql("'totalShInf'"), @users_tb[:total_share_influence],

				Arel.sql("'totalShares'"), @users_tb[:total_shares],
				Arel.sql("'totalPosts'"), @users_tb[:total_posts],
				Arel.sql("'regTime'"), arel_sql_epoch(@users_tb, :created_at),

				Arel.sql("'followStatus'"), Arel.sql(<<-SQL.squish
					CASE WHEN #{current_user.try(:id) || 'NULL'} IS NULL THEN
						NULL
					WHEN "user_relationships"."id" IS NOT NULL THEN
						TRUE
					ELSE
						FALSE
					END
				SQL
				)
			).as('user_data')
		)
		.join(@urels_tb, Arel::Nodes::OuterJoin)
		.on(
			@users_tb[:id].eq(@urels_tb[:follows_id])
			.and(@urels_tb[:follower_id].eq(current_user.try(:id)))
		)

		# authors
		@authors_query_ast = @users_query_ast.dup
		.where(
			@users_tb[:id].in(
				@posts_search_cte.project(@posts_search_cte[:user_id])
			)
		)
		@authors_cte = Arel::Table.new(:authors_cte)
		@authors_cte_as = Arel::Nodes::As.new(@authors_cte, @authors_query_ast)

		# publishers
		@publishers_query_ast = @users_query_ast.dup
		.where(
			@users_tb[:id].in(
				@infs_search_cte.project(@infs_search_cte[:user_id])
			)
		)
		@publishers_cte = Arel::Table.new(:publishers_cte)
		@publishers_cte_as = Arel::Nodes::As.new(@publishers_cte, @publishers_query_ast)


		# inf data
		@infs_tb = Influence.arel_table
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
				@infs_search_cte.project(@infs_search_cte[:post_id])
			)
		)
		.group(@infs_tb[:post_id])

		@inf_data_cte = Arel::Table.new(:inf_data_cte)
		@inf_data_cte_as = Arel::Nodes::As.new(@inf_data_cte, @inf_data_query_ast)


		# infs
		@infs_query_ast = @infs_search_cte
		.project(
			@infs_search_cte[:infId],
			@infs_search_cte[:infType],
			@infs_search_cte[:publishTime],

			@infs_search_cte[:content],
			@infs_search_cte[:totalReads],
			@infs_search_cte[:totalShares],
			@infs_search_cte[:createTime],

			@authors_cte[:user_data].as('"author"'),
			@publishers_cte[:user_data].as('"publisher"'),

			@inf_data_cte[:graphData]	
		)
		.join(@authors_cte, Arel::Nodes::OuterJoin)
		.on(
			@infs_search_cte[:author_id].eq(@authors_cte[:id])
		)
		.join(@publishers_cte, Arel::Nodes::OuterJoin)
		.on(
			@infs_search_cte[:user_id].eq(@publishers_cte[:id])
		)
		.join(@inf_data_cte, Arel::Nodes::OuterJoin)
		.on(
			@infs_search_cte[:post_id].eq(@inf_data_cte[:post_id])
		)

		@infs_cte = Arel::Table.new(:infs_cte)
		@infs_cte_as = Arel::Nodes::As.new(@infs_cte, @infs_query_ast)


		# agg infs
		@infs_agg_query = Arel.sql(<<-SQL.squish
			(SELECT JSON_AGG("posts_agg") AS "posts_agg"
			FROM (#{
				@infs_cte.project(
					@infs_cte[:infId],
					@infs_cte[:infType],
					@infs_cte[:publishTime],
					@infs_cte[:content],

					@infs_cte[:totalReads],
					@infs_cte[:totalShares],
					@infs_cte[:createTime],

					@infs_cte[:author],
					@infs_cte[:publisher],

					@infs_cte[:graphData]
				).to_sql
			}) AS "posts_agg")
		SQL
		)
		@infs_agg_cte = Arel::Table.new(:infs_agg_cte)
		@infs_agg_cte_as = Arel::Nodes::As.new(@infs_agg_cte, @infs_agg_query)



		@query_ast = @users_agg_cte
		.project(
			@users_agg_cte[:users_agg].as('"users"'),
			@infs_agg_cte[:posts_agg].as('"posts"')
		)
		.join(
			@infs_agg_cte
		).on(Arel.sql('TRUE'))
		.with(
			@users_search_cte_as,
			@users_agg_cte_as,

			@posts_search_cte_as,
			@infs_search_cte_as,

			@authors_cte_as,
			@publishers_cte_as,
			@inf_data_cte_as,

			@infs_cte_as,
			@infs_agg_cte_as
		)

		# return render text: @query_ast.to_sql

		render jsonize(
			json_agg_exec(@query_ast, prefix: 'SELECT SET_LIMIT(0.05);').first
		)
	end

	private


end
