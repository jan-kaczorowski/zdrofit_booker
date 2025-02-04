class CreateZdrofitClassBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :zdrofit_class_bookings do |t|
      t.integer :class_id
      t.integer :club_id
      t.datetime :next_occurence
      t.references :zdrofit_user, null: false, foreign_key: true
      t.string :status
      t.string :mode
      t.string :class_name
      t.string :trainer_name
      t.timestamps
    end
  end
end
