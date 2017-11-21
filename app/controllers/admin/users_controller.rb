class Admin::UsersController < Admin::AdminsController

  include Scraper
  include SlackNotification
  WEBHOOK_URL = 'https://hooks.slack.com/services/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'.freeze
  require 'swap_word'

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
    raise MyError::AdminDeleteHimselfError if admin_delete_himself? params[:id]
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path
  end

  def update
    @user = User.find(params[:id])
    raise MyError::UpdateFailError.new @user.errors.messages unless @user.update(user_params)
    redirect_to user_path(@user)
  end

  def create
    @user = User.new(user_params)
    raise MyError::CreateFailError.new @user.errors.messages unless @user.save
    flash[:success] = 'Welcome to the EH Order Lunch App!'
    redirect_to @user
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
    render plain: 'manage_company'
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
    render plain: 'manage_all_days'
  end


  def manage_company(fetch_date = Date.today)
    @menu = Menu.find_by_date(fetch_date)
    @today_orders = Order.where("DATE(date)=?", fetch_date)

    today_all_ordered_dishes = @today_orders.map {|t| t.dishes}
    today_all_ordered_dishes = today_all_ordered_dishes.flatten

    counted_dishes = Hash.new(0).tap {|h| today_all_ordered_dishes.each {|dish| h[dish] += 1}}
    counted_dishes.delete_if {|k, v| k.id.nil?}

    all_costs = {}
    counted_dishes.each do |dish, count|
      restaurant = dish.restaurant
      if !all_costs.has_key? restaurant
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

  def export_manage_pdf
    manage_company
    respond_to do |format|
      format.html
      format.pdf do
        pdf = ManagePagePdf.new @presenter
        send_data pdf.render, filename: 'order_report.pdf', type: 'application/pdf'
      end
    end
  end

  def scrap_data
    # p Scraper::HeadersScraper.new.crawl

    before = 'https://www.foody.vn/ho-chi-minh'
    after = 'goi-mon'
    # res_url = 'hung-map-bun-moc-bun-bo-hue'
    # res_url = 'pho-le-vo-van-tan'
    # res_url = 'trieu-phong-vo-van-tan'
    # res_url = 'pho-le-nguyen-trai'
    # res_url = 'hoang-ky-com-ga-xoi-mo'
    # res_url = 'vi-sai-gon-bun-thit-nuong'
    # res_url = 'banh-canh-cua-14-tran-binh-trong'
    # res_url = 'ut-huong'
    # res_url = 'tylum-hu-tieu-nam-vang'
    # res_url = 'hai-tu-quy-bun-ca-ro-dong-nem-cua-be'
    res_url = 'quan-yen-bun-ca-sua-nha-trang-le-hong-phong'
    res_url = ''
    full_url = File.join before, res_url, after
    a = Scraper::TestScraper.new.crawl full_url
    # a = Scraper::GitRepoScraper.new.crawl
    @dishes = a['dishes']
    @coupon = a['coupon']
  end

  def ping_slack
    #notifier = Slack::Notifier.new WEBHOOK_URL, channel: "#test-order-lunch", username: "notifier"

    # notifier.ping "Hello Duong"
    # notifier.ping "Hello order lunch"

    #message = "Hello world, [check](http://example.com) it <a href='http://example.com'>out</a>"
    # message = "Go to [here](#{ol_link}) to order lunch"

    # message = "<!channel> hey check [this](#{ol_link}) out"
    # message = Slack::Notifier::Util::LinkFormatter.format(message)

    # link_text = Slack::Notifier::Util::Escape.html("User <duong.vu@employmenthero.com>")
    # message = "Write to [#{link_text}](mailto:duong.vu@employmenthero.com)"
    # notifier.ping message

    # notifier.post text: "feeling spooky", icon_emoji: ":ghost:"
    # notifier.post text: "feeling chimpy", icon_url: "http://static.mailchimp.com/web/favicon.png"
    #
    # a_ok_note = {
    #     fallback: "Everything looks peachy",
    #     text: "Everything looks peachy",
    #     color: "good"
    # }
    # notifier.post text: "with an attachment", attachments: [a_ok_note]

    # notifier.post text: "please order lunch", at: [:here, :waldo, :Vu_Tien_Duong, "Vu Tien Duong".to_sym]

    #notifier.post text: "hello channel", channel: ["test-order-lunch", "@duong.vu"]

    # notifier = Slack::Notifier.new WEBHOOK_URL do
    #   middleware :swap_words # setting our stack w/ just defaults
    # end

    #notifier.ping "hipchat is awesome!"
    # => pings slack with "slack is awesome!"

    # notifier = Slack::Notifier.new WEBHOOK_URL do
    #   # here we set new options for the middleware
    #   middleware swap_words: { pairs: ["hipchat" => "slack",
    #                                    "awesome" => "really awesome"]}
    # end
    #
    # notifier.ping "hipchat is awesome!"

    #notifier.post text: 'please order lunch', channel: "@duong.vu"

    @result = send_notify_request_order
    render 'send_notify_result'
  end


  private
  def user_params
    if params[:user][:password].blank?
      params[:user].except!(:password)
    end
    params.require(:user).permit(:username, :email, :password, :admin, :slack_name)
  end

  def admin_delete_himself? deleted_id
    session[:is_admin] && deleted_id == session[:user_id]
  end
end