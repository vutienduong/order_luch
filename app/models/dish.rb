require "open-uri"
class Dish < ActiveRecord::Base
  attr_reader :image_logo_remote_url
  validates :name, presence: true, uniqueness: {scope: :restaurant, message: 'each restaurant doesn\'t have two dishes which are same named'}

  validates_numericality_of :price, greater_than_or_equal_to: 1000

  validates_presence_of :restaurant

  belongs_to :restaurant

  has_many :dish_orders
  has_many :orders, through: :dish_orders
  has_many :sized_prices

  belongs_to :parent, class_name: 'Dish'
  has_many :variants, class_name: 'Dish', foreign_key: 'parent_id'

  has_many :dish_component_associations
  has_many :dished_components, through: :dish_component_associations

  has_and_belongs_to_many :tags

  has_attached_file :image_logo, styles: {
      thumb: '100x100>',
      square: '200x200#',
      medium: '300x300>'
  }

  # Validate the attached image is image/jpg, image/png, etc
  validates_attachment_content_type :image_logo, :content_type => /\Aimage\/.*\Z/

  def image_logo_remote_url=(url_value)
    self.image_logo = URI.parse(url_value)
    @image_logo_remote_url = url_value
  end

  def display_name
    name.split(/\[[^\[]*\]/).last
  end
end
