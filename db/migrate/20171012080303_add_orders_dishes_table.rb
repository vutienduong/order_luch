class AddOrdersDishesTable < ActiveRecord::Migration
  def change
    create_table :orders_dishes do |t|
      t.belongs_to :orders, index: true
      t.belongs_to :dish, index: true
      t.timestamps
    end
  end
end
