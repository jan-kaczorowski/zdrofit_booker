class BookingCheckerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "foo"
  end
end
