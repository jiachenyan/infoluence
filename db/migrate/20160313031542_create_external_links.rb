class CreateExternalLinks < ActiveRecord::Migration
  def change
    create_table :external_links do |t|
      t.text :url, index: true, null: false
      t.text :origin, index: true, null: false
      t.decimal :trend_value, index: true, null: false, default: 0
      t.jsonb :properties

      t.timestamps null: false
    end
    add_attachment :external_links, :image
  end
end
