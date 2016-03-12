class AddStatsToUsersAndPosts < ActiveRecord::Migration
	def change
		remove_column :users, :total_influence

		add_column :users, :total_read_influence, :integer, index: true, null: false, default: 0
		add_column :users, :total_share_influence, :integer, index: true, null: false, default: 0
		add_column :users, :total_shares, :integer, null: false, default: 0
		add_column :users, :total_posts, :integer, null: false, default: 0

		add_column :posts, :total_reads, :integer, index: true, null: false, default: 0
		add_column :posts, :total_shares, :integer, index: true, null: false, default: 0

		change_column_null :influences, :from_inf_id, null: true

		add_index :influences, [:type, :post_id]
	end
end
