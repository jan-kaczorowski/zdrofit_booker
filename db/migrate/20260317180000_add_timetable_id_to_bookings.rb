class AddTimetableIdToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :timetable_id, :integer
  end
end
