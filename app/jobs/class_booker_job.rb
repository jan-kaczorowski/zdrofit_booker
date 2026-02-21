class ClassBookerJob < ApplicationJob
  queue_as :default

  retry_on ClassBooker::TransientError, wait: :polynomially_longer, attempts: 10 do |job, error|
    booking = ZdrofitClassBooking.find(job.arguments.first)
    booking.update!(status: "failed", debug_info: "Po 10 próbach (~4.5h): #{error.message}")
  end

  def perform(booking_id)
    booking = ZdrofitClassBooking.find(booking_id)
    ClassBooker.call(booking)
  end
end
