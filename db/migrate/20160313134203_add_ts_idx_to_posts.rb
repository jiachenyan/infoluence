class AddTsIdxToPosts < ActiveRecord::Migration
	def up
		execute <<-SQL.squish
			CREATE INDEX gin_tsv_index_posts_on_title
			ON posts 
			USING gin(
				to_tsvector('english', "posts"."content" ->> 'title')
			);
		SQL
	end

	def down
		execute 'DROP INDEX gin_tsv_index_posts_on_title;'
	end
end
