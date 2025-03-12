class ZdrofitClassBooking < ApplicationRecord
  belongs_to :zdrofit_user

  def booking_time
    next_occurrence_utc = ActiveSupport::TimeZone["Europe/Warsaw"]
                            .parse(next_occurrence)
                            .in_time_zone("UTC")
    next_occurrence_utc - 2.days + 1.minute
  end

  after_create :book_class

  private

  def book_class
    ClassBookerJob.set(wait_until: booking_time).perform_later(id)
  end
end
