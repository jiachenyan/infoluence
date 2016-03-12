class PostsController < ApplicationController
	def create
		post = Post.new(params.slice(*User.attribute_names))
	end
end
