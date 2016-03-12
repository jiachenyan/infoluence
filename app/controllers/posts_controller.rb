class PostsController < ApplicationController
	before_action :signed_in_user, only: [:create]

	def create
		post = current_user.posts.new
		post.content = params[:content]

		render jsonize({todo: 'det post'})
	end

	def send_post
		render jsonize({todo: 'det post'})
	end

	def send_timeline
		render jsonize({todo: 'timeline'})
	end

	private

	def serialize_post
		# todo
	end
end
