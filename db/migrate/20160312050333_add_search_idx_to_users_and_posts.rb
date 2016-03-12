class AddSearchIdxToUsersAndPosts < ActiveRecord::Migration
	def up
		enable_extension 'pg_trgm';

		execute 'CREATE INDEX gin_index_users_on_username ON users USING gin (username gin_trgm_ops);'
		execute 'CREATE INDEX gin_index_users_on_name ON users USING gin (name gin_trgm_ops);';

		execute 'CREATE INDEX gin_index_posts_on_content ON posts USING gin (content jsonb_path_ops);';
	end

	def down
		disable_extension 'pg_trgm'

		execute 'DROP INDEX gin_index_users_on_username;'
		execute 'DROP INDEX gin_index_users_on_name;'

		execute 'DROP INDEX gin_index_posts_on_content;';
	end
end
