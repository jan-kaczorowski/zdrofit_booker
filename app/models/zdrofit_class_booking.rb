class ZdrofitClassBooking < ApplicationRecord
  belongs_to :zdrofit_user

  # Interprets the stored datetime as Warsaw local time
  # (The API returns times in Warsaw timezone without offset)
  def next_occurrence_in_warsaw
    ActiveSupport::TimeZone["Europe/Warsaw"].local(
      next_occurrence.year,
      next_occurrence.month,
      next_occurrence.day,
      next_occurrence.hour,
      next_occurrence.min,
      next_occurrence.sec
    )
  end

  # Returns the class start time in UTC
  def next_occurrence_utc
    next_occurrence_in_warsaw.utc
  end

  # Returns the time when the booking job should run
  # Booking opens exactly 2 days before class at the same Warsaw time
  # Add 10 seconds buffer to ensure the booking API is ready
  def booking_time
    (next_occurrence_in_warsaw - 2.days + 10.seconds).utc
  end

  def available_seats_count
    zdrofit_user.zdrofit_api_client
                .get_class_details(class_id: class_id)
                .dig("BookingIndicator", "Available")&.to_i
  end

  after_create :book_class

  private

  def book_class
    if booking_time.past?
      ClassBookerJob.perform_later(id)
    elsif available_seats_count < 1
      ClassBookerJob.wait_until(30.minutes.from_now).perform_later(id)
    else
      ClassBookerJob.set(wait_until: booking_time).perform_later(id)
    end
  end
end
