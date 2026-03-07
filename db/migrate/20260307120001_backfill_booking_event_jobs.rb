class BackfillBookingEventJobs < ActiveRecord::Migration[8.0]
  def up
    # The split migration inserted booking_events via raw SQL, so after_create
    # callbacks (which schedule ClassBookerJob) never fired. Fix that here:

    # 1. Fail stale pending events whose class time has already passed
    execute <<~SQL
      UPDATE booking_events
      SET status = 'failed', debug_info = 'Stale po migracji — zajęcia już minęły'
      WHERE status = 'pending'
        AND occurrence < CURRENT_TIMESTAMP
    SQL

    # 2. Schedule jobs for remaining pending events (future occurrences)
    BookingEvent.where(status: "pending").find_each do |event|
      if event.booking_time.past?
        ClassBookerJob.perform_later(event.id)
      else
        ClassBookerJob.set(wait_until: event.booking_time).perform_later(event.id)
      end
    end
  end

  def down
    # No-op: jobs will simply run and find current state
  end
end
