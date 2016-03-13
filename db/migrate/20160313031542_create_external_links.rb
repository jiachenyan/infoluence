class CreateExternalLinks < ActiveRecord::Migration
  def change
    create_table :external_links do |t|
      t.text :url
      t.text :origin
      t.jsonb :properties

      t.timestamps null: false
    end
    add_attachment :users, :image
  end
end
