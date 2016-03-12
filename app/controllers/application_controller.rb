class ApplicationController < ActionController::Base
	include ApplicationHelper
	include UsersHelper
	include PostsHelper
	

  protect_from_forgery with: :exception
end
