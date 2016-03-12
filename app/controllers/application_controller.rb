class ApplicationController < ActionController::Base
	include ApplicationHelper
	include UsersHelper
	include PostsHelper
	
  protect_from_forgery with: :exception

  before_action :set_no_cache, :correct_auth

	private

	def set_no_cache
		response.headers["Cache-Control"] = "private, no-cache, no-store, must-revalidate, max-age=0"
		response.headers["Pragma"] = "no-cache, no-store"
		response.headers["Expires"] = "-1"
		response.headers["Connection"] = "close"
	end

	def correct_authentication
		sign_out if cookies[:user_token].present? and current_user.blank?
	end
end
