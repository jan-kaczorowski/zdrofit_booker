class AddDebugInfoToZdrofitClassBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :zdrofit_class_bookings, :debug_info, :string
  end
end
