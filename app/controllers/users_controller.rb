class UsersController < ApplicationController
	before_action :signed_in_user,
		only: [:update, :update_avatar, :destroy_session]

	def create
		user = User.new(params.slice(*User.attribute_names))
		user.password = params[:password]
		pass_conf = params[:passwordConfirmation]
		user.password_confirmation = pass_conf unless pass_conf.blank? # can be empty string

		if user.save
			sign_in(user)
			render json_success("Created #{user.name}")
		else
			render json_error(user)
		end
	end

	def user_info
		user = User.find_by_username(params[:username])
		return render json_error('Invalid user') unless user.present?

		render jsonize({
			name: user.name,
			username: user.username,
			totalInf: user.total_influence,
			avatarThumb: user.avatar.url(:thumb),
			avatarMedium: user.avatar.url(:medium),
			regTime: user.created_at.to_i
		})
	end

	def update
		if params[:password].present?
			current_user.password = params[:password]
			current_user.password_confirmation = params[:password_confirmation]
		end
		# todo
		# if current_user.update_attributes(params)
		# 	sign_in(current_user)
		# 	# render jsonize(serialize_curr_user)
		# else
		# 	render json_error(current_user)
		# end
	end

	def update_avatar
	end

	def create_session
		# if params[:login].include? '@'
			# user = User.find_by_email(params[:login])
		# else
			user = User.find_by_username(params[:login])
		# end

		if user.present? and user.authenticate(params[:password])
			sign_in user
			render json_success('Logged in')
		else
			render json_error('Invalid login')
		end
	end

	def destroy_session
		sign_out
		render json_success('Logged out')
	end
end