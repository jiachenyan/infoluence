class CreateInfluences < ActiveRecord::Migration
  def change
    create_table :influences do |t|
      t.text :type, null: false
      t.references :user, index: true, foreign_key: true # null on OC
      t.references :post, index: true, foreign_key: true, null: false
      t.integer :from_inf_id, index: true, null: false
      t.jsonb :properties

      t.timestamps null: false
    end

    add_foreign_key :influences, :influences, column: :from_inf_id
    add_index :influences, :type, using: :btree


    create_table :user_relationships do |t|
      t.integer :follower_id, index: true, null: false
      t.integer :follows_id, index: true, null: false

      t.timestamps null: false
    end

    add_foreign_key :user_relationships, :users, column: :follower_id, primary_key: :id
    add_foreign_key :user_relationships, :users, column: :follows_id, primary_key: :id
  end
end
