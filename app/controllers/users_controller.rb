class UsersController < ApplicationController
	before_action :signed_in_user,
		only: [:update, :update_avatar, :destroy_session, :update_relationship]

	FOLLOWINGS_PER_PAGE = 50

	def create
		user = User.new(params.slice(*User.attribute_names))
		user.password = params[:password]
		pass_conf = params[:password_confirmation]
		user.password_confirmation = pass_conf unless pass_conf.blank? # can be empty string

		if user.save
			sign_in(user)
			render jsonize(serialize_user(user))
		else
			render json_error(user)
		end
	end

	def update
		if params[:password].present?
			# authenticate to change password
			return render json_error('Invalid password') unless user.authenticate(params[:old_password])

			current_user.password = params[:password]
			current_user.password_confirmation = params[:password_confirmation]
		end

		current_user.assign_attributes(params.slice(*User.attribute_names))
		
		if params[:info].present?
			current_user.properties = Hash.new if current_user.properties.nil?
			current_user.properties[:info] = params[:info]
		end

		if current_user.save
			sign_in(current_user)
			render jsonize(serialize_user(current_user))
		else
			render json_error(current_user)
		end
	end

	def update_avatar
		return render json_error('Invalid upload') if params[:file].blank?

		user = current_user
		temp_user = User.new
		temp_user.avatar = user.avatar

		user.avatar = params[:file]
		return render json_error(user) unless user.save
		
		begin 
			url = user.avatar.url(:medium)
			img = Nokogiri::HTML(open(url))
			# file opened successfully

			sign_in(user)
			render jsonize(serialize_user(user))
		rescue => e
			user.update_attribute(:avatar, temp_user.avatar)
			sign_in(user)
			render json_error('upload unsuccessful')
		end
	end

	def user_info
		user = User.find_by_username(params[:username])
		return render json_error('Invalid user') unless user.present?

		render jsonize(serialize_user(user))
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

	def update_relationship
		follows_user = User.find_by_username(params[:username])
		return render json_error('Invalid user to follow') if follows_user.blank?
			
		if current_user.update_relationship(follows_user)
			render jsonize({
				username: follows_user.username,
				following: current_user.follows?(follows_user)
			})
		else
			render json_error('Invalid user to follow')
		end
	end

	def send_followings
		user = User.find_by_username(params[:username])
		return render json_error('Invalid username') if user.blank?

		# relationship
		@urels_tb = UserRelationship.arel_table
		@users_tb = User.arel_table

		@urels_query_ast = @urels_tb
		.project(
				@users_tb[:name],
				@users_tb[:username],
				avatar_url_attr(:thumb, :avatarThumb),
				avatar_url_attr(:medium, :avatarMedium),
				Arel.sql('"users"."properties" -> \'info\'').as('"userInfo"'),

				@users_tb[:total_read_influence].as('"totalRdInf"'),
				@users_tb[:total_share_influence].as('"totalShInf"'),
				@users_tb[:total_shares].as('"totalShares"'),
				@users_tb[:total_posts].as('"totalPosts"'),

				arel_sql_epoch(@users_tb, :created_at, :regTime),
				Arel.sql('TRUE').as('"followStatus"')
		)
		.where(@urels_tb[:follower_id].eq(user.id))
		.join(@users_tb)
		.on(
			@urels_tb[:follows_id].eq(@users_tb[:id])
		)

		@urels_query_ast = paginate(@urels_query_ast, params[:page], FOLLOWINGS_PER_PAGE)

		render jsonize(json_agg_exec(@urels_query_ast))
	end

	private

	def serialize_user(user)
		{
			name: user.name,
			username: user.username,
			avatarThumb: user.avatar.url(:thumb),
			avatarMedium: user.avatar.url(:medium),

			userInfo: user.properties.try(:[], 'info'),

			totalRdInf: user.total_read_influence,
			totalShInf: user.total_share_influence,
			totalShares: user.total_shares,
			totalPosts: user.total_posts,

			regTime: user.created_at.to_i,
			followStatus: current_user.try(:follows?, user)
		}
	end
end