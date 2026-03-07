require 'rails_helper'

RSpec.describe BookingEvent, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  before { allow(ClassBookerJob).to receive(:perform_later) }
  before { allow(ClassBookerJob).to receive_message_chain(:set, :perform_later) }

  describe '#booking_time' do
    context 'winter time (UTC+1)' do
      let(:event) { build(:booking_event, occurrence: DateTime.new(2026, 1, 20, 18, 30, 0)) }

      it 'schedules 2 days before at 18:30:10 Warsaw (17:30:10 UTC)' do
        expect(event.booking_time).to eq(Time.utc(2026, 1, 18, 17, 30, 10))
      end
    end

    context 'summer time (UTC+2)' do
      let(:event) { build(:booking_event, occurrence: DateTime.new(2026, 7, 20, 18, 30, 0)) }

      it 'schedules with DST offset (16:30:10 UTC)' do
        expect(event.booking_time).to eq(Time.utc(2026, 7, 18, 16, 30, 10))
      end
    end
  end

  describe '#occurrence_in_warsaw' do
    let(:event) { build(:booking_event, occurrence: DateTime.new(2026, 1, 20, 18, 30, 0)) }

    it 'returns the time in Warsaw timezone' do
      result = event.occurrence_in_warsaw
      expect(result.zone).to eq('CET')
      expect(result.hour).to eq(18)
      expect(result.min).to eq(30)
    end
  end

  describe '#occurrence_utc' do
    context 'winter time' do
      let(:event) { build(:booking_event, occurrence: DateTime.new(2026, 1, 20, 18, 30, 0)) }

      it 'converts Warsaw time to UTC (UTC+1 in winter)' do
        expect(event.occurrence_utc).to eq(Time.utc(2026, 1, 20, 17, 30, 0))
      end
    end

    context 'summer time' do
      let(:event) { build(:booking_event, occurrence: DateTime.new(2026, 7, 20, 18, 30, 0)) }

      it 'converts Warsaw time to UTC (UTC+2 in summer)' do
        expect(event.occurrence_utc).to eq(Time.utc(2026, 7, 20, 16, 30, 0))
      end
    end
  end

  describe '#time_until_booking' do
    it 'returns past message when booking time has passed' do
      event = build(:booking_event, occurrence: 1.day.ago)

      expect(event.time_until_booking).to eq("Okno rezerwacji minęło")
    end

    it 'returns less than a minute when under 60 seconds' do
      # booking_time = occurrence_in_warsaw - 2.days + 10.seconds (in UTC)
      # Set occurrence to a fixed Warsaw-local time, then freeze clock so
      # booking_time is ~30 seconds in the future.
      # occurrence = 2026-01-20 18:30:00 Warsaw → booking_time = 2026-01-18 17:30:10 UTC
      event = build(:booking_event, occurrence: DateTime.new(2026, 1, 20, 18, 30, 0))

      # 30 seconds before booking_time
      travel_to Time.utc(2026, 1, 18, 17, 29, 40) do
        expect(event.time_until_booking).to eq("Mniej niż minuta")
      end
    end

    it 'returns countdown with days and hours' do
      event = build(:booking_event, occurrence: 5.days.from_now)

      result = event.time_until_booking
      expect(result).to start_with("za ")
      expect(result).to include("dni")
    end
  end

  describe '#schedule_booking_job' do
    let(:user) { create(:zdrofit_user) }
    let(:booking) { create(:booking, zdrofit_user: user) }

    before do
      allow(ClassBookerJob).to receive(:perform_later)
      allow(ClassBookerJob).to receive_message_chain(:set, :perform_later)
    end

    it 'schedules job immediately when booking_time is in the past' do
      event = booking.booking_events.create!(occurrence: 1.day.from_now, status: "pending")

      expect(ClassBookerJob).to have_received(:perform_later).with(event.id)
    end

    it 'schedules job for booking_time when in the future' do
      set_double = double("set")
      allow(ClassBookerJob).to receive(:set).and_return(set_double)
      allow(set_double).to receive(:perform_later)

      event = booking.booking_events.create!(occurrence: 5.days.from_now, status: "pending")

      expect(ClassBookerJob).to have_received(:set).with(wait_until: event.booking_time)
      expect(set_double).to have_received(:perform_later).with(event.id)
    end

    it 'does not schedule job for non-pending events' do
      allow(ClassBookerJob).to receive(:perform_later)

      booking.booking_events.create!(occurrence: 5.days.from_now, status: "booked")

      expect(ClassBookerJob).not_to have_received(:perform_later)
    end
  end
end
