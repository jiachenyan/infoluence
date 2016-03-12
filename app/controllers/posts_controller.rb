class PostsController < ApplicationController
	before_action :signed_in_user, only: [:create]

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
		render jsonize(serialize_posts)
	end

	private

	def serialize_post
		query_ast = posts_query_ast
		.where(@post_tb[:id].eq(@post.id))
		json_agg_exec(query_ast).first
	end

	def serialize_posts
		query_ast = posts_query_ast
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
