module UsersHelper
	def sign_in(user)
		cookies.permanent[:user_token] = user.token
		cookies.permanent[:userInfo] = Oj.dump({
			username: user.username,
			name: user.name,
			avatarThumb: user.avatar.url(:thumb),
			avatarMedium: user.avatar.url(:medium)
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
		@current_user ||= User.find_by_token(cookies[:user_token])
	end

	def signed_in_user
		unless signed_in?
			respond_to do |format|
				format.all { redirect_to root_path }
				format.json { return render json_error("User not signed in") }
			end
		end
	end

	private 

	# serializer helpers

	def user_projs
		users_tb = User.arel_table
		[
			users_tb[:name],
			users_tb[:username],
			avatar_url_attr(:thumb, :avatarThumb),
			avatar_url_attr(:medium, :avatarMedium),
			users_tb[:total_read_influence].as('"totalRdInf"'),
			users_tb[:total_share_influence].as('"totalShInf"'),
			users_tb[:total_shares].as('"totalShares"'),
			users_tb[:total_posts].as('"totalPosts"'),
			arel_sql_epoch(users_tb, :created_at, :regTime)
		]
	end

	def avatar_url_attr(style, as_name=nil)
		arel_sql = Arel.sql <<-SQL.squish
			CASE WHEN "users"."avatar_file_name" IS NOT NULL  THEN
				'http://s3.amazonaws.com/infoluence/users/avatars/' ||
				TO_CHAR("users"."id",'FM000/000/000') ||
				'/#{style}/' || "users"."avatar_file_name" || '?' ||
				CAST(EXTRACT('EPOCH' FROM "users"."avatar_updated_at") AS INT)
			WHEN "users"."id" IS NULL THEN
				NULL
			ELSE
				'http://s3.amazonaws.com/infoluence/default_avatar.jpg'
			END
		SQL

		arel_sql = arel_sql.as("\"#{as_name}\"") unless as_name.nil?
		arel_sql
	end

	def json_build_object(*values)
		Arel::Nodes::NamedFunction.new('JSON_BUILD_OBJECT', values)
	end
end
