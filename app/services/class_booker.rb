# t.integer "class_id"
# t.integer "club_id"
# t.datetime "next_occurrence"
# t.integer "zdrofit_user_id", null: false
# t.string "status"
# t.string "mode"
# t.string "class_name"
# t.string "trainer_name"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false

class ClassBooker
  def initialize(booking)
    @booking = booking
    @user = booking.user
  end

  def self.call(booking)
    new(booking).call
  end

  def call
    zdrofit_api_client = @user.zdrofit_api_client
    zdrofit_api_client.book_class(@booking.class_id)
    booking.update!(status: "booked", next_occurrence: booking.next_occurrence + 1.week)
    ClassBookerJob.set(wait_until: booking.booking_time).perform_later(booking.id)
  rescue => e
    booking.update!(status: "failed")
    raise e
  end

  private

  attr_reader :booking, :user
end
