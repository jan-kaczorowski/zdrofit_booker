class ClassBooker
  class TransientError < StandardError; end

  TRANSIENT_PATTERNS = [
    /SSL_read/i,
    /Failed to open TCP connection/i,
    /execution expired/i,
    /Connection reset by peer/i,
    /Connection refused/i,
    /Net::OpenTimeout/i,
    /Net::ReadTimeout/i,
    /SocketError/i,
    /ECONNREFUSED/i,
    /ETIMEDOUT/i,
    /ECONNRESET/i,
    /unexpected eof/i,
    /end of file reached/i
  ].freeze

  def initialize(event)
    @event = event
    @booking = event.booking
    @user = @booking.zdrofit_user
    @zdrofit_api_client = @user.zdrofit_api_client
  end

  def self.call(event)
    new(event).call
  end

  def call
    unless @event.occurrence_utc > 2.hours.from_now
      @event.update!(status: "failed", debug_info: "Nie udało się zarezerwować - lista zamrożona (<2h do zajęć)")
      return
    end

    if available_seats_count.positive?
      @zdrofit_api_client.book_class(class_id: @booking.class_id, club_id: @booking.club_id)
      @event.update!(status: "booked")
      @booking.booking_events.create!(occurrence: @event.occurrence + 1.week)
    else
      ClassBookerJob.set(wait_until: 1.hour.from_now).perform_later(@event.id)
    end
  rescue => e
    if transient_error?(e)
      ZdrofitClient.rotate_proxy
      @event.update!(debug_info: "transient: #{e.message}")
      raise TransientError, e.message
    else
      @event.update!(status: "failed", debug_info: e.message)
      raise e
    end
  end

  private

  def available_seats_count
    @zdrofit_api_client
      .get_class_details(class_id: @booking.class_id)
      .dig("BookingIndicator", "Available")&.to_i || 0
  end

  def transient_error?(error)
    TRANSIENT_PATTERNS.any? { |pattern| error.message.match?(pattern) }
  end
end
