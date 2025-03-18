class ChangeColumnDefaultsOnBookings < ActiveRecord::Migration[8.0]
  def change
    change_column_default :zdrofit_class_bookings, :status, from: nil, to: 'pending' 
  end
end
