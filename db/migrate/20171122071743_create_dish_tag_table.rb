class CreateDishTagTable < ActiveRecord::Migration
  def change
    create_table :dishes_tags do |t|
      t.references :tags
      t.integer :dish_id
      t.integer :tag_id
    end
  end
end
