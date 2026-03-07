class Booking < ApplicationRecord
  self.table_name = "bookings"

  belongs_to :zdrofit_user
  has_many :booking_events, dependent: :destroy

  def current_event
    booking_events.select { |e| e.status == "pending" && e.occurrence > Time.current }.min_by(&:occurrence)
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
