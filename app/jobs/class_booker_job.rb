class ClassBookerJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = ZdrofitClassBooking.find(booking_id)
    ClassBooker.call(booking)
  end
end
