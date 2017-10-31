class Menu < ActiveRecord::Base
  validates :restaurants, presence: true
  validates :date, uniqueness: true

  has_many :menu_restaurants
  has_many :restaurants, through: :menu_restaurants
  accepts_nested_attributes_for :restaurants
end
