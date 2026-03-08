class BookingEvent < ApplicationRecord
  belongs_to :booking

  after_create :schedule_booking_job

  # Interprets the stored datetime as Warsaw local time
  # (The API returns times in Warsaw timezone without offset)
  def occurrence_in_warsaw
    ActiveSupport::TimeZone["Europe/Warsaw"].local(
      occurrence.year,
      occurrence.month,
      occurrence.day,
      occurrence.hour,
      occurrence.min,
      occurrence.sec
    )
  end

  def occurrence_utc
    occurrence_in_warsaw.utc
  end

  # Returns the time when the booking job should run
  # Booking opens exactly 2 days before class at the same Warsaw time
  # Add 5 seconds buffer to ensure the booking API is ready
  def booking_time
    (occurrence_in_warsaw - 2.days + 5.seconds).utc
  end

  def booking_time_in_warsaw
    booking_time.in_time_zone("Europe/Warsaw")
  end

  # Returns a human-readable countdown to booking time (in Polish)
  def time_until_booking
    return "Okno rezerwacji minęło" if booking_time.past?

    seconds = (booking_time - Time.current).to_i
    return "Mniej niż minuta" if seconds < 60

    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60

    parts = []
    parts << pluralize_polish(days, "dzień", "dni", "dni") if days > 0
    parts << pluralize_polish(hours, "godzina", "godziny", "godzin") if hours > 0
    parts << pluralize_polish(minutes, "minuta", "minuty", "minut") if minutes > 0 && days == 0

    "za #{parts.join(', ')}"
  end

  private

  def pluralize_polish(count, one, few, many)
    if count == 1
      "#{count} #{one}"
    elsif count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)
      "#{count} #{few}"
    else
      "#{count} #{many}"
    end
  end

  def schedule_booking_job
    return unless status == "pending"

    if booking_time.past?
      ClassBookerJob.perform_later(id)
    else
      ClassBookerJob.set(wait_until: booking_time).perform_later(id)
    end
  end
end
