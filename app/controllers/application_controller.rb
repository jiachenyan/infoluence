class ApplicationController < ActionController::Base
	include UsersHelper
	include ApplicationHelper

  protect_from_forgery with: :exception
end
