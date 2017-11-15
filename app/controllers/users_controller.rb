class UsersController < ApplicationController
  STATUS_OK = 'ok'.freeze
  STATUS_FAIL = 'fail'.freeze
  MSG_SUCCESS = 'Success!'.freeze

  def admin?
    @user.admin
  end

  def index
    @users = User.all
  end

  def show
    @user = User.find_by(id: params[:id])


  end

  def edit
    check_user_permission params[:id].to_i
    @user = retrieve_user params[:id]
  end

  def update
    check_user_permission params[:id].to_i
    @user = retrieve_user params[:id]
    raise MyError::UpdateFailError unless @user.update(user_params)
    redirect_to user_path(@user)
  end

  def select_dish
    @var1 = 'Var 1'
    redirect_to controller: 'restaurants', action: 'show_detail', id: params[:id], select_dish: 1
  end

  def order
    @menu = Menu.find_by(date: Date.today)

    if @menu.blank?
      render 'menus/request_menu'
    else
      @today_order = find_order_by_user_id_and_date session[:user_id], Date.today

      session[:today_order] = @today_order.blank? ? nil : @today_order
      session[:today_order_id] = session[:today_order].blank? ? nil : session[:today_order]['id']

      @dishes = []
      @menu.restaurants.each {|r| @dishes.push(r.dishes)}
      @dishes.flatten!
      @total_price = @today_order.blank? ? 0 : @today_order.cal_total_price
    end

    # all orders
    @all_orders = Order.where('DATE(date)=?', Date.today)
  end

  def get_all_orders_today
    @all_orders = Order.where('DATE(date)=?', Date.today)
    render 'get_all_orders_today'
  end

  def delete_today_order_session
    session[:today_order] = nil
    render plain: 'Delete today orders session'
  end

  def save_order
    add_dish_params
    if params[:dish][:action] == 'add'
      add_dish_to_order
    else
      remove_dish_from_order
    end
  end

  def _add_dish_to_order_back_up
    order_params = {user_id: session[:user_id], date: Date.today}
    @order = find_order_by_user_id_and_date session[:user_id], Date.today
    @order = Order.create! order_params if @order.blank?

    DishOrder.create!(order_id: @order.id, dish_id: params[:dish][:dish_id])
    msg = {status: STATUS_OK, message: MSG_SUCCESS, today: @order}
    response_to_json msg
  end

  def _remove_dish_from_order_back_up
    @order = find_order_by_user_id_and_date session[:user_id], Date.today
    unless @order.blank?
      @order_dishes = DishOrder.where('order_id = ? AND dish_id = ?', @order.id, params[:dish][:dish_id]).all
      @order_dishes.last.destroy if @order_dishes.length >= 1
      order = Order.find_by(id: order_id)
      order.destroy if order.blank? || order.dishes.blank?
    end
    msg = {status: STATUS_OK, message: MSG_SUCCESS, today: @order}
    response_to_json msg
  end

  def add_dish_to_order
    @log = {} # Note: relate to @log[] = ... later, can cause error without this initialize
    order_params = {user_id: session[:user_id], date: Date.today}
    retrieve_order_and_update_session order_params

    # add dish for that order
    @order_dish = DishOrder.new(order_id: session[:today_order][:id], dish_id: params[:dish][:dish_id])
    msg = @order_dish.save ? {status: STATUS_OK, message: MSG_SUCCESS, today: session[:today_order]} : {status: STATUS_FAIL}

    # guarantee that always response json
    response_to_json msg
  end

  def remove_dish_from_order
    unless session[:today_order].blank?
      order_id = session[:today_order]['id']
      @order_dishes = DishOrder.where('order_id = ? AND dish_id = ?',
                                      order_id,
                                      params[:dish][:dish_id]).all
      @order_dishes.last.destroy if @order_dishes.length >= 1
      order = Order.find_by(id: order_id)
      destroy_order_and_update_session order if order.blank? || order.dishes.blank?
    end

    # guarantee that always response json
    msg = {status: STATUS_OK, message: MSG_SUCCESS, today: session[:today_order]}
    response_to_json msg
  end

  def add_dish_to_order_no_ajax
    add_dish_to_order_params
    order = Order.find(session[:today_order_id])
    unless order.blank?
      dish_order = DishOrder.new(order_id: session[:today_order_id], dish_id: params[:dish_id])
      redirect_to order_user_path(session[:user_id]) if dish_order.save
    end
  end

  def add_dish
    redirect_to '/users/test'
  end

  def edit_note
    order_id = session[:today_order_id]
    @order = Order.find_by(id: order_id)
    msg = {}
    msg[:status] = @order.blank? ? STATUS_FAIL : (@order.update(edit_note_params) ? STATUS_OK : STATUS_FAIL)

    respond_to do |format|
      format.json {render :json => msg}
    end
  end

  def copy_order
    copy_info_params
    current_order_id = session[:today_order_id]
    @dish_orders = DishOrder.where(order_id: current_order_id).all
    @dish_orders.each {|d| d.destroy}

    # add all copied dishes follow copied user
    unless params[:copy_info][:dish_ids].blank?
      params[:copy_info][:dish_ids].each do |d|
        @dish_order = DishOrder.new(order_id: current_order_id, dish_id: d)
        @dish_order.save
      end
    end

    # update note
    @order = Order.find(current_order_id)
    @order.update_attributes(note: params[:copy_info][:note]) unless @order.blank?
    redirect_to order_user_path(session[:user_id])
  end


  def test
  end

  def test_ajax
    users = User.where('email LIKE ? ', "%#{params[:keyword]}%").limit(10)
    respond_to do |format|
      format.json {render json: {status: STATUS_OK, users: users}}
    end
  end

  def get_dish
  end

  private

  def retrieve_order_and_update_session order_params
    @order = find_order_by_user_id_and_date order_params[:user_id], order_params[:date]
    @order = Order.create! order_params if @order.blank?
    session[:today_order] = @order
    session[:today_order_id] = @order.id
  end

  def destroy_order_and_update_session order
    order.destroy
    session[:today_order_id] = nil
    session[:today_order] = nil
  end

  def add_dish_to_order_params
    params.permit(:dish_id)
  end

  def user_params
    params.require(:user).permit(:username, :email, :password)
  end

  def add_dish_params
    params.require(:dish).permit(:user_id, :dish_id, :action, :order_id)
  end

  def edit_note_params
    params.require(:order).permit(:order_id, :note)
  end

  def copy_info_params
    params.require(:copy_info).permit(:dish_ids, :user_id, :order_id, :note)
  end

  def response_to_json msg
    respond_to do |format|
      format.json {render json: msg}
    end
  end

  def query_date_string date
    "date LIKE '%#{date}%'"
  end

  def check_user_permission edit_user_id
    raise MyError::NonPermissionEditError unless (edit_user_id == session[:user_id] || session[:is_admin])
  end

  def retrieve_user id
    user = User.find_by id: id
    raise MyError::NonExistRecordError unless user
    user
  end

  def find_order_by_user_id_and_date user_id, date
    Order.where('DATE(date)=?', date).where('user_id = ?', user_id).first
  end
end

