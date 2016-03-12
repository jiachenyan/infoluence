module UsersHelper
	def sign_in(user)
		cookies.permanent[:user_token] = user.token
		cookies.permanent[:userInfo] = Oj.dump({
			username: user.username,
			name: user.name
		})
		@current_user = user
	end

	def signed_in?
		!current_user.nil?
	end

	def sign_out
		@current_user = nil

		cookies.delete(:user_token)
		cookies.delete(:userInfo)
	end
	
	def set_current_user(user)
		@current_user = user
	end

	def current_user
		@current_user ||= User.find_by_remember_token(cookies[:user_token])
	end

	def signed_in_user
		unless signed_in?
			respond_to do |format|
				format.all { redirect_to root_path }
				format.json { return render json_error("User not signed in") }
			end
		end
	end
end
