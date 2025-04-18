class ZdrofitClassBooking < ApplicationRecord
  belongs_to :zdrofit_user

  def booking_time
    next_occurrence_utc - 2.days + 1.minute
  end

  def next_occurrence_utc
    ActiveSupport::TimeZone["Europe/Warsaw"]
                            .parse(next_occurrence.iso8601)
                            .in_time_zone("UTC")
  end

  after_create :book_class

  private

  def available_seats_count
    zdrofit_user.zdrofit_api_client
                .get_class_details(class_id: class_id)
                .dig("BookingIndicator", "Available")&.to_i
  end

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
