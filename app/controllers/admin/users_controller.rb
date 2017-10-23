class Admin::UsersController < AdminsController

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
    if session[:is_admin] and params[:id].to_i == session[:user_id]
      @error = ErrorCode::ERR_USER_DELETE_CURRENT_ADMIN
      render 'layouts/error'
    else
      @user.destroy
      redirect_to users_path
    end
  end

  def update
    @user = User.find(params[:id])
    #render params.inspect
    #return
    if @user.update(user_params)
      redirect_to user_path(@user)
    else
      render plain: 'edit fail'
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      #log_in @user
      flash[:success] = "Welcome to the EH Order Lunch App!"
      redirect_to @user
    else
      render 'create'
    end
  end

  def manage
    @users = User.all
    @menus = Menu.includes(:restaurants).all
    @restaurants = Restaurant.includes(:dishes).all
    @dishes = Dish.all
  end

  def get_manage
    @date = Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
    manage_company(@date)
    render 'manage_company'
  end

  def manage_all_days
    @date = Date.today
    @order = Order.new
    manage_company(Date.today)
  end

  def manage_all
    @order = Order.new #dummy, TODO: remove it
    @date = Date.civil(params[:order]["date(1i)"].to_i, params[:order]["date(2i)"].to_i, params[:order]["date(3i)"].to_i)
    manage_company(@date)
    render 'manage_all_days'
  end


  def manage_company(fetch_date = Date.today)
    @menu = Menu.find_by_date(fetch_date)
    @today_orders = Order.where("DATE(date)=?", fetch_date)
    #today_all_order_ids = @today_orders.map(&:id)
    #today_all_ordered_dishes = DishOrder.where(order_id: today_all_order_ids)

    today_all_ordered_dishes = @today_orders.map {|t| t.dishes}
    today_all_ordered_dishes = today_all_ordered_dishes.flatten

    counted_dishes = Hash.new(0).tap {|h| today_all_ordered_dishes.each {|dish| h[dish] += 1}}
    counted_dishes.delete_if {|k, v| k.id.nil?}

    all_costs = {}
    counted_dishes.each do |dish, count|
      restaurant = dish.restaurant
      unless all_costs.has_key? restaurant
        all_costs[restaurant] = {}
        all_costs[restaurant][:dishes] = {dish => {count: count, cost: dish.price * count}}
        all_costs[restaurant][:cost] = dish.price * count
      else
        all_costs[restaurant][:dishes][dish] = {count: count, cost: dish.price * count}
        all_costs[restaurant][:cost] += dish.price * count
      end
    end
    total_cost = all_costs.values.inject(0) {|sum, e| sum + e[:cost]}

    @presenter = {menu: @menu,
                  today_order: @today_orders,
                  counted_dishes: counted_dishes,
                  all_costs: all_costs,
                  total_cost: total_cost,
                  budget: @today_orders.length * 80000
    }
  end


  private
  def user_params
    params.require(:user).permit(:username, :email, :password, :admin)
  end

end