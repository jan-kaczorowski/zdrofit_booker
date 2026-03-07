require 'rails_helper'

RSpec.describe Booking, type: :model do
  before { allow(ClassBookerJob).to receive(:perform_later) }
  before { allow(ClassBookerJob).to receive_message_chain(:set, :perform_later) }

  let(:user) { create(:zdrofit_user) }
  let(:booking) { create(:booking, zdrofit_user: user) }

  describe '#current_event' do
    it 'returns the earliest pending event in the future' do
      create(:booking_event, booking: booking, status: "pending", occurrence: 3.days.from_now)
      later = create(:booking_event, booking: booking, status: "pending", occurrence: 10.days.from_now)

      expect(booking.current_event.occurrence).to be_within(1.second).of(3.days.from_now)
    end

    it 'ignores booked events' do
      create(:booking_event, booking: booking, status: "booked", occurrence: 3.days.from_now)

      expect(booking.current_event).to be_nil
    end

    it 'ignores past pending events' do
      create(:booking_event, booking: booking, status: "pending", occurrence: 1.day.ago)

      expect(booking.current_event).to be_nil
    end

    it 'returns nil when no events exist' do
      expect(booking.current_event).to be_nil
    end
  end

  describe '#last_booked_event' do
    it 'returns the most recent booked event' do
      create(:booking_event, booking: booking, status: "booked", occurrence: 1.week.ago)
      latest = create(:booking_event, booking: booking, status: "booked", occurrence: 1.day.ago)

      expect(booking.last_booked_event).to eq(latest)
    end

    it 'ignores pending events' do
      create(:booking_event, booking: booking, status: "pending", occurrence: 3.days.from_now)

      expect(booking.last_booked_event).to be_nil
    end
  end

  describe '#latest_failed_event' do
    it 'returns the most recently created failed event' do
      old_fail = create(:booking_event, booking: booking, status: "failed", occurrence: 2.weeks.ago)
      new_fail = create(:booking_event, booking: booking, status: "failed", occurrence: 1.week.ago)

      expect(booking.latest_failed_event).to eq(new_fail)
    end

    it 'returns nil when no failed events' do
      create(:booking_event, booking: booking, status: "booked", occurrence: 1.day.ago)

      expect(booking.latest_failed_event).to be_nil
    end
  end

  describe '#active?' do
    it 'returns true when a future pending event exists' do
      create(:booking_event, booking: booking, status: "pending", occurrence: 3.days.from_now)

      expect(booking).to be_active
    end

    it 'returns false when no future pending events' do
      create(:booking_event, booking: booking, status: "booked", occurrence: 1.day.ago)

      expect(booking).not_to be_active
    end
  end

  describe '#failed?' do
    it 'returns true when any event has failed status' do
      create(:booking_event, booking: booking, status: "failed", occurrence: 1.week.ago)

      expect(booking).to be_failed
    end

    it 'returns false when no failed events' do
      create(:booking_event, booking: booking, status: "booked", occurrence: 1.day.ago)

      expect(booking).not_to be_failed
    end
  end

  describe 'associations' do
    it 'destroys booking_events when destroyed' do
      create(:booking_event, booking: booking, status: "pending", occurrence: 3.days.from_now)
      create(:booking_event, booking: booking, status: "booked", occurrence: 1.week.ago)

      expect { booking.destroy }.to change(BookingEvent, :count).by(-2)
    end
  end
end
