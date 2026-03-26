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
      schedule_next_week
      return
    end

    unless resolve_class_id
      @event.update!(debug_info: "Nie znaleziono zajęć w kalendarzu, ponowna próba za 1h")
      ClassBookerJob.set(wait_until: 1.hour.from_now).perform_later(@event.id)
      return
    end

    if available_seats_count.positive?
      @zdrofit_api_client.book_class(class_id: @booking.class_id, club_id: @booking.club_id)
      @event.update!(status: "booked")
      schedule_next_week
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
      schedule_next_week
      raise e
    end
  end

  private

  # Resolves the correct class_id for this week's occurrence.
  # The Zdrofit API assigns a different Id to each weekly occurrence,
  # so we look up the current one by timetable_id + date match.
  def resolve_class_id
    ensure_timetable_id
    return true unless @booking.timetable_id

    classes = @zdrofit_api_client.list_weekly_classes(
      club_id: @booking.club_id,
      time_table_id: @booking.timetable_id
    )

    target = @event.occurrence
    matching = classes.find do |c|
      t = DateTime.parse(c["StartTime"])
      t.day == target.day && t.month == target.month && t.year == target.year &&
        t.hour == target.hour && t.min == target.min
    end

    return false unless matching

    @booking.update!(class_id: matching["Id"]) if @booking.class_id != matching["Id"]
    true
  end

  # Backfills timetable_id for bookings created before this field existed.
  def ensure_timetable_id
    return if @booking.timetable_id

    details = @zdrofit_api_client.get_class_details(class_id: @booking.class_id)
    timetable_id = details.dig("ClassRatingSummaryInfo", "TimeTableId")
    @booking.update!(timetable_id: timetable_id) if timetable_id
  end

  def available_seats_count
    @zdrofit_api_client
      .get_class_details(class_id: @booking.class_id)
      .dig("BookingIndicator", "Available")&.to_i || 0
  end

  def schedule_next_week
    @booking.booking_events.create!(occurrence: @event.occurrence + 1.week)
  end

  def transient_error?(error)
    TRANSIENT_PATTERNS.any? { |pattern| error.message.match?(pattern) }
  end
end
