class RemoveMenuFromRestaurants < ActiveRecord::Migration
  def change
    remove_reference :restaurants, :menu, index: true, foreign_key: true
  end
end
