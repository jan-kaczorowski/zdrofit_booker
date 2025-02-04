class ZdrofitClassBooking < ApplicationRecord
  belongs_to :zdrofit_user

  def booking_time
    next_occurrence - 2.days + 1.minute
  end

  after_create :book_class

  private

  def book_class
    ClassBookerJob.set(wait_until: booking_time).perform_later(id)
  end
end
