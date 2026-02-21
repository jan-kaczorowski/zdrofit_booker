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

  def initialize(booking)
    @booking = booking
    @user = booking.zdrofit_user
    @zdrofit_api_client = @user.zdrofit_api_client
  end

  def self.call(booking)
    new(booking).call
  end

  def call
    unless @booking.next_occurrence_utc > 2.hours.from_now
      @booking.update!(status: "failed", debug_info: "Nie udało się zarezerwować - lista zamrożona (<2h do zajęć)")
      return
    end

    if @booking.available_seats_count.to_i.positive?
      @zdrofit_api_client.book_class(class_id: @booking.class_id, club_id: @booking.club_id)
      @booking.update!(status: "booked", next_occurrence: @booking.next_occurrence + 1.week)
      ClassBookerJob.set(wait_until: @booking.booking_time).perform_later(@booking.id)
    else
      ClassBookerJob.set(wait_until: 30.minutes.from_now).perform_later(@booking.id)
    end
  rescue => e
    if transient_error?(e)
      ZdrofitClient.rotate_proxy
      @booking.update!(debug_info: "transient: #{e.message}")
      raise TransientError, e.message
    else
      @booking.update!(status: "failed", debug_info: e.message)
      raise e
    end
  end

  private

  def transient_error?(error)
    TRANSIENT_PATTERNS.any? { |pattern| error.message.match?(pattern) }
  end
end
