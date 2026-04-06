class Booking < ApplicationRecord
  self.table_name = "bookings"

  belongs_to :zdrofit_user
  has_many :booking_events, dependent: :destroy

  # Next upcoming event (pending or already booked) — this is what we display
  def current_event
    @current_event ||= booking_events
      .select { |e| e.occurrence > Time.current && e.status.in?(%w[pending booked]) }
      .min_by(&:occurrence)
  end

  # Next pending event — used for sort order (closest auto-booking first)
  def next_pending_event
    @next_pending_event ||= booking_events
      .select { |e| e.status == "pending" && e.occurrence > Time.current }
      .min_by(&:occurrence)
  end

  # Most recent completed event BEFORE the current one — shows last attempt result
  def previous_completed_event
    cutoff = current_event&.occurrence
    events = booking_events.select { |e| e.status.in?(%w[booked failed]) }
    events = events.select { |e| e.occurrence < cutoff } if cutoff
    events.max_by(&:occurrence)
  end

  def last_booked_event
    booking_events.select { |e| e.status == "booked" }.max_by(&:occurrence)
  end

  def latest_failed_event
    booking_events.select { |e| e.status == "failed" }.max_by(&:created_at)
  end

  def active? = current_event.present?
  def failed? = booking_events.any? { |e| e.status == "failed" }
end
