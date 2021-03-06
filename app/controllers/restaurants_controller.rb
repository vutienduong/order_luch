class RestaurantsController < ApplicationController
  before_action :require_login
  def show
    @restaurant = Restaurant.includes(:dishes).find(params[:id])
    @today_order = Order.find(session[:today_order_id]) if session.key? :today_order_id
  end

  def show_detail
    @restaurant = Restaurant.includes(:dishes).find(params[:id])
    render 'show_dish_details'
  end

  def index
    @restaurants = Restaurant.includes('dishes').all
  end
end
