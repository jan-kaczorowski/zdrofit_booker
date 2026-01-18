require 'rails_helper'

RSpec.describe ZdrofitClassBooking, type: :model do
  describe '#booking_time' do
    context 'winter time (UTC+1)' do
      let(:booking) do
        build(:zdrofit_class_booking,
          next_occurrence: DateTime.new(2026, 1, 20, 18, 30, 0))
      end

      it 'schedules 2 days before at 18:30:10 Warsaw (17:30:10 UTC)' do
        expect(booking.booking_time).to eq(Time.utc(2026, 1, 18, 17, 30, 10))
      end
    end

    context 'summer time (UTC+2)' do
      let(:booking) do
        build(:zdrofit_class_booking,
          next_occurrence: DateTime.new(2026, 7, 20, 18, 30, 0))
      end

      it 'schedules with DST offset (16:30:10 UTC)' do
        expect(booking.booking_time).to eq(Time.utc(2026, 7, 18, 16, 30, 10))
      end
    end
  end

  describe '#next_occurrence_in_warsaw' do
    let(:booking) do
      build(:zdrofit_class_booking,
        next_occurrence: DateTime.new(2026, 1, 20, 18, 30, 0))
    end

    it 'returns the time in Warsaw timezone' do
      result = booking.next_occurrence_in_warsaw
      expect(result.zone).to eq('CET')
      expect(result.hour).to eq(18)
      expect(result.min).to eq(30)
    end
  end

  describe '#next_occurrence_utc' do
    context 'winter time' do
      let(:booking) do
        build(:zdrofit_class_booking,
          next_occurrence: DateTime.new(2026, 1, 20, 18, 30, 0))
      end

      it 'converts Warsaw time to UTC (UTC+1 in winter)' do
        expect(booking.next_occurrence_utc).to eq(Time.utc(2026, 1, 20, 17, 30, 0))
      end
    end

    context 'summer time' do
      let(:booking) do
        build(:zdrofit_class_booking,
          next_occurrence: DateTime.new(2026, 7, 20, 18, 30, 0))
      end

      it 'converts Warsaw time to UTC (UTC+2 in summer)' do
        expect(booking.next_occurrence_utc).to eq(Time.utc(2026, 7, 20, 16, 30, 0))
      end
    end
  end
end
