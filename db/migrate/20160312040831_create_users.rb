class CreateUsers < ActiveRecord::Migration
	def change
		create_table :users do |t|
			t.text :name, null: false
			t.text :username, index: true, null: false
			t.text :email, index: true, null: false
			t.text :password_digest, null: false

			t.text :token, index: true, null: false

			t.integer :total_influence, null: false

			t.jsonb :properties
			t.timestamps null: false
		end
		add_attachment :users, :avatar

		create_table :posts do |t|
			t.references :user, index: true, foreign_key: true
			t.jsonb :content

			t.jsonb :properties
			t.timestamps null: false
		end
	end
end
