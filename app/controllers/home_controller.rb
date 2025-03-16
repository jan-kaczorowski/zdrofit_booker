class HomeController < ApplicationController
  before_action :authenticate_user!, except: %i[index login]

  def index
  end

  def login
    @user = ZdrofitUser.find_or_create_by(email: params[:email]) do |user|
      user.pass = params[:password]
    end

    # Test the credentials by trying to login to Zdrofit
    begin
      @user.zdrofit_client = @user.zdrofit_api_client
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Successfully logged in"
    rescue => e
      flash[:error] = "Invalid credentials: #{e.message}"
      redirect_to root_path
    end
  end

  def dashboard
    @user = ZdrofitUser.find(session[:user_id])
    @client = @user.zdrofit_api_client
    @clubs = @client.list_available_clubs
  rescue => e
    flash[:error] = "Failed to fetch clubs: #{e.message}"
    @clubs = []
  end

  def weekly_classes
    @user = ZdrofitUser.find(session[:user_id])
    client = @user.zdrofit_api_client
    @classes = client.list_weekly_classes(
      club_id: params[:club_id],
      date: 10.days.from_now.strftime("%F")
    )
    # binding.break
    render json: @classes
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def book
    @user = ZdrofitUser.find(session[:user_id])

    begin
      # Create booking record with next_occurrence
      ZdrofitClassBooking.create!(
        zdrofit_user: @user,
        class_id: params[:class_id],
        club_id: params[:club_id],
        next_occurrence: params[:next_occurrence],
        class_name: params[:class_name],
        trainer_name: params[:trainer_name]
      )

      render json: { success: true }
    rescue => e
      render json: { success: false, error: e.message }
    end
  end

  def update_location
    @user = ZdrofitUser.find(session[:user_id])
    @user.update_last_location(
      city_id: params[:city_id],
      club_id: params[:club_id]
    )
    head :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def authenticate_user!
    return unless session[:user_id].blank?

    redirect_to index_path and return
  end
end
