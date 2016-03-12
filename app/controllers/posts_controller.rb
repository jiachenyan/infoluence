class PostsController < ApplicationController
	before_action :signed_in_user, only: [:create]

	POSTS_PER_PAGE = 20

	def create
		@post = current_user.posts.new
		@post.content = params[:content]

		if @post.save
			# todo: params[:inf_id]
			render jsonize(serialize_post)
		else
			render json_error(@post)
		end
	end

	def send_post
		@post = Post.find_by_id(params[:id])
		return render json_error('Invalid post') unless @post.present?
		render jsonize(serialize_post)
	end

	def send_timeline
		render jsonize(serialize_posts(params[:page]))
	end

	def send_follow_timeline
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
		@user_tb = User.arel_table

		projs = post_projs + user_projs

		@post_tb.project(projs)
		.join(@user_tb)
		.on(@user_tb[:id].eq(@post_tb[:user_id]))

		#todo: join graph data
		#todo: join influence info
	end
end
