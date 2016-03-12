class PostsController < ApplicationController
	before_action :signed_in_user, only: [:create]

	POSTS_PER_PAGE = 20

	def create
		@post = current_user.posts.new
		@post.content = params[:content]

		if @post.save
			# +1 to user no. posts
			# add to influence, null user_id

			# add to post_links (low pri, for data purposes)

			# todo: params[:inf_id]
			render jsonize(serialize_post)
		else
			render json_error(@post)
		end
	end

	def send_post
		@post = Post.find_by_id(params[:id])
		return render json_error('Invalid post') unless @post.present?

		# +1 to user no. read
		# add influence read
		render jsonize(serialize_post)
	end

	def send_timeline
		render jsonize(serialize_posts(params[:page]))
	end

	def send_follow_timeline
		# posts = posts union influences
		render jsonize({todo: 'following timeline'})
	end

	private

	def serialize_post
		query_ast = posts_query_ast
		.where(@post_tb[:id].eq(@post.id))
		json_agg_exec(query_ast).first
	end

	def serialize_posts(page=1)
		query_ast = paginate(
			posts_query_ast, page, POSTS_PER_PAGE
		)
		.order(@post_tb[:created_at].desc)
		# todo: paginate
		json_agg_exec(query_ast)
	end

	def posts_query_ast
		@post_tb = Post.arel_table
		@users_tb = User.arel_table

		# posts_cte_projs = post_projs
		# posts_cte_projs << posts_tb[:user_id]
		# posts_ast = posts_tb.project(posts_cte_projs)

		# @posts_cte = Arel::Table.new(:posts_cte)
		# @authors_cte = Arel::Table.new(:authors_cte)
		# # @influencers_cte = Arel::Table.new(:influencers_cte)

		# @posts_cte_as = posts_cte_as(@posts_cte)
		# @authors_cte_as = users_cte(@authors_cte)

		
		# OLD posts_query_ast

		projs = post_projs + user_projs

		@post_tb.project(projs)
		.join(@users_tb)
		.on(@users_tb[:id].eq(@post_tb[:user_id]))

		#todo: join graph data
		#todo: join influence info
	end

	# def posts_query_post(posts_cte_as)
	# 	Arel::Nodes::As.new(posts_cte, posts_ast)

	# 	@post_query_projs = post_projs
	# 	projs << @authors_cte[:info].as('"author"')
	# 	# projs << @influencers_projs[:info].as('"influencer"')

	# 	query_ast = posts_cte.project(@post_query_projs)
	# 	.join(@authors_cte)
	# 	.on(post_projs[:user_id].eq(@authors_cte[:id]))
	# 	.with(
	# 		@posts_cte_as,
	# 		@authors_cte_as
	# 		# influencers_cte
	# 	)
	# end
end
