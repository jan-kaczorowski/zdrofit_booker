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
      @user.zdrofit_api_client # This will login and cache the token
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Zalogowano pomyślnie"
    rescue => e
      flash[:error] = "Nieprawidłowe dane logowania: #{e.message}"
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
    all_bookings = @user.bookings.includes(:booking_events).to_a
    @pending_bookings = all_bookings.select(&:active?).sort_by { |b| b.current_event.occurrence }
    @failed_bookings = all_bookings.reject(&:active?).select(&:failed?)

    # If it's a Turbo Frame request, render the partial
    if turbo_frame_request?
      render partial: "ongoing_bookings", locals: {
        pending_bookings: @pending_bookings,
        failed_bookings: @failed_bookings
      }
    else
      # For API requests, return JSON
      render json: { pending: @pending_bookings, failed: @failed_bookings }
    end
  rescue => e
    Rails.logger.error("Error fetching ongoing bookings: #{e.message}")
    if turbo_frame_request?
      render html: "<turbo-frame id=\"ongoing-bookings-container\"><div class='p-4 bg-red-100 text-red-700 rounded'>Error: #{e.message}</div></turbo-frame>".html_safe
    else
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def cancel_booking
    booking = Booking.find_by(id: params[:id], zdrofit_user: @user)

    if booking&.destroy
      render json: { success: true }
    else
      render json: { success: false, error: "Booking not found or could not be deleted" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def weekly_classes
    if params[:club_id]
      already_booked_class_ids = @user.bookings.where(club_id: params[:club_id]).pluck(:class_id)
      client = @user.zdrofit_api_client
      @classes = client.list_weekly_classes(
        club_id: params[:club_id],
        date: 10.days.from_now.strftime("%F")
      )

      # Generate next 5 days for tabs (Polish labels)
      polish_days = %w[Niedz Pon Wt Śr Czw Pt Sob]
      polish_days_full = %w[Niedziela Poniedziałek Wtorek Środa Czwartek Piątek Sobota]
      polish_months = %w[sty lut mar kwi maj cze lip sie wrz paź lis gru]

      @next_5_days = (0..4).map do |i|
        date = Date.current + i
        day_abbr = polish_days[date.wday]
        day_full = polish_days_full[date.wday]
        month_abbr = polish_months[date.month - 1]
        {
          date: date,
          label: date == Date.current ? "Dziś" : "#{day_abbr} #{date.day}",
          day_name: day_full,
          formatted: "#{day_full}, #{date.day} #{month_abbr}"
        }
      end

      # Filter classes to only show the next 5 days
      five_days_from_now = Date.current + 5
      @classes = @classes.select do |cl|
        class_date = DateTime.parse(cl["StartTime"]).to_date
        class_date >= Date.current && class_date < five_days_from_now
      end

      # Group classes by date
      @classes_by_date = @classes.group_by do |cl|
        DateTime.parse(cl["StartTime"]).to_date
      end

      # Mark classes that already have bookings
      @classes.each do |cl|
        cl["BookingId"] = already_booked_class_ids.include?(cl["Id"]) ? true : nil
      end

      # Default to first day with classes or today
      @selected_date = if params[:date].present?
        Date.parse(params[:date])
      else
        @next_5_days.first[:date]
      end
    else
      @classes, @classes_by_date, @next_5_days = [], {}, []
      @selected_date = Date.current
    end

    # If it's a Turbo Frame request, render the partial
    if turbo_frame_request?
      render partial: "weekly_classes", locals: {
        classes: @classes,
        classes_by_date: @classes_by_date,
        next_5_days: @next_5_days,
        selected_date: @selected_date
      }
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
      booking = @user.bookings.create!(
        class_id: params[:class_id],
        club_id: params[:club_id],
        class_name: params[:class_name],
        trainer_name: params[:trainer_name],
        timetable_id: params[:timetable_id]
      )
      booking.booking_events.create!(occurrence: params[:next_occurrence])

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
