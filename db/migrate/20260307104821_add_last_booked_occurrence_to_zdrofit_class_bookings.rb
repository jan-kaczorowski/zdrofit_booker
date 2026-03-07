class AddLastBookedOccurrenceToZdrofitClassBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :zdrofit_class_bookings, :last_booked_occurrence, :datetime
  end
end
