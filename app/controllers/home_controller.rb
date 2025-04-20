class HomeController < ApplicationController
  before_action :authenticate_user!, except: %i[index login]
  before_action :fetch_user, except: %i[index login]

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
    @client = @user.zdrofit_api_client
    @clubs = @client.list_available_clubs
  rescue => e
    flash[:error] = "Failed to fetch clubs: #{e.message}"
    @clubs = [] # Ensure @clubs is always an array
  end

  def ongoing_bookings
    @bookings = ZdrofitClassBooking.where(zdrofit_user: @user)
    # If it's a Turbo Frame request, render the partial
    if turbo_frame_request?
      render partial: "ongoing_bookings", locals: { bookings: @bookings }
    else
      # For API requests, return JSON
      render json: @bookings
    end
  rescue => e
    Rails.logger.error("Error fetching ongoing bookings: #{e.message}")
    if turbo_frame_request?
      render html: "<turbo-frame id=\"ongoing-bookings-container\"><div class='p-4 bg-red-100 text-red-700 rounded'>Error: #{e.message}</div></turbo-frame>".html_safe
    else
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def weekly_classes
    if params[:club_id]
    @bookings = ZdrofitClassBooking.where(zdrofit_user: @user, club_id: params[:club_id])
                                   .select(:id, :class_id, :next_occurrence)
    client = @user.zdrofit_api_client
    @classes = client.list_weekly_classes(
      club_id: params[:club_id],
      date: 10.days.from_now.strftime("%F")
    )
    else
      @bookings, @classes = [], []
    end

    @classes.each do |cl|
      match = @bookings.find { |b| b.class_id == cl["Id"] && b.next_occurrence == DateTime.parse(cl["StartTime"]) }
      cl["BookingId"] = match&.id
    end
    # binding.break
    # If it's a Turbo Frame request, render the partial
    if turbo_frame_request?
      render partial: "weekly_classes", locals: { classes: @classes }
    else
      # For API requests, return JSON
      render json: @classes
    end
  rescue => e
    Rails.logger.error("Error fetching weekly classes: #{e.message}")
    if turbo_frame_request?
      render html: "<turbo-frame id=\"weekly-classes-container\"><div class='p-4 bg-red-100 text-red-700 rounded'>Error: #{e.message}</div></turbo-frame>".html_safe
    else
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def book
    begin
      # Create booking record with next_occurrence
      ZdrofitClassBooking.create!(
        zdrofit_user: @user,
        status: "pending",
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

    redirect_to root_path and return
  end

  def fetch_user
    return if session[:user_id].blank?

    @user = ZdrofitUser.find(session[:user_id])
  end
end
