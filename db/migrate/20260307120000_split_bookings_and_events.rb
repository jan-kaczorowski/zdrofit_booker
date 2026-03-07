class SplitBookingsAndEvents < ActiveRecord::Migration[8.0]
  def up
    create_table :booking_events do |t|
      t.integer :booking_id, null: false
      t.datetime :occurrence, null: false
      t.string :status, default: "pending", null: false
      t.string :debug_info
      t.timestamps
    end
    add_index :booking_events, :booking_id

    rename_table :zdrofit_class_bookings, :bookings

    add_foreign_key :booking_events, :bookings

    # Migrate current pending/upcoming occurrences
    execute <<~SQL
      INSERT INTO booking_events (booking_id, occurrence, status, debug_info, created_at, updated_at)
      SELECT id, next_occurrence, COALESCE(status, 'pending'), debug_info, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM bookings
      WHERE next_occurrence IS NOT NULL
    SQL

    # Migrate previously booked occurrences
    execute <<~SQL
      INSERT INTO booking_events (booking_id, occurrence, status, created_at, updated_at)
      SELECT id, last_booked_occurrence, 'booked', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM bookings
      WHERE last_booked_occurrence IS NOT NULL
    SQL

    remove_column :bookings, :status
    remove_column :bookings, :debug_info
    remove_column :bookings, :last_booked_occurrence
    remove_column :bookings, :mode
    remove_column :bookings, :next_occurrence
  end

  def down
    add_column :bookings, :status, :string, default: "pending"
    add_column :bookings, :debug_info, :string
    add_column :bookings, :last_booked_occurrence, :datetime
    add_column :bookings, :mode, :string
    add_column :bookings, :next_occurrence, :datetime

    execute <<~SQL
      UPDATE bookings SET
        next_occurrence = (
          SELECT occurrence FROM booking_events
          WHERE booking_events.booking_id = bookings.id AND booking_events.status = 'pending'
          ORDER BY occurrence ASC LIMIT 1
        ),
        status = COALESCE(
          (SELECT status FROM booking_events
           WHERE booking_events.booking_id = bookings.id AND booking_events.status != 'booked'
           ORDER BY created_at DESC LIMIT 1),
          'pending'
        ),
        debug_info = (
          SELECT debug_info FROM booking_events
          WHERE booking_events.booking_id = bookings.id
          ORDER BY created_at DESC LIMIT 1
        ),
        last_booked_occurrence = (
          SELECT occurrence FROM booking_events
          WHERE booking_events.booking_id = bookings.id AND booking_events.status = 'booked'
          ORDER BY occurrence DESC LIMIT 1
        )
    SQL

    remove_foreign_key :booking_events, :bookings
    drop_table :booking_events
    rename_table :bookings, :zdrofit_class_bookings
  end
end
