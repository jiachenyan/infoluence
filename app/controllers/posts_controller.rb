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
		render jsonize({todo: 'timeline'})
	end

	private

	def serialize_post
		post_tb = Post.arel_table
		user_tb = User.arel_table

		projs = post_projs + user_projs

		query_ast = post_tb.project(projs)
		.join(user_tb)
		.on(user_tb[:id].eq(post_tb[:user_id]))
		.where(post_tb[:id].eq(@post.id))
		#todo: join graph data
		#todo: join influence info

		json_agg_exec(query_ast).first
	end
end
