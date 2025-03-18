class ClassBooker
  def initialize(booking)
    @booking = booking
    @user = booking.zdrofit_user
    @zdrofit_api_client = @user.zdrofit_api_client
  end

  def self.call(booking)
    new(booking).call
  end

  def call
    
    @zdrofit_api_client.book_class(class_id: @booking.class_id, club_id: @booking.club_id)
    @booking.update!(status: "booked", next_occurrence: @booking.next_occurrence + 1.week)
    ClassBookerJob.set(wait_until: @booking.booking_time).perform_later(@booking.id)
  rescue => e
    @booking.update!(status: "failed", debug_info: e.message)
    raise e
  end
end
