class ClassBookerJob < ApplicationJob
  queue_as :default

  retry_on ClassBooker::TransientError, wait: :polynomially_longer, attempts: 10 do |job, error|
    event = BookingEvent.find(job.arguments.first)
    event.update!(status: "failed", debug_info: "Po 10 próbach (~4.5h): #{error.message}")
  end

  def perform(event_id)
    event = BookingEvent.find(event_id)
    ClassBooker.call(event)
  end
end
