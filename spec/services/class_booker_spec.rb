require 'rails_helper'

RSpec.describe ClassBooker do
  include ActiveSupport::Testing::TimeHelpers

  before { allow(ClassBookerJob).to receive(:perform_later) }
  before { allow(ClassBookerJob).to receive_message_chain(:set, :perform_later) }

  let(:user) { create(:zdrofit_user) }
  let(:booking) { create(:booking, zdrofit_user: user, class_id: 42, club_id: 7) }
  let(:api_client) { double("ZdrofitClient::Client") }

  before do
    allow(user).to receive(:zdrofit_api_client).and_return(api_client)
    booking.reload
    allow(booking).to receive(:zdrofit_user).and_return(user)
  end

  describe '#call' do
    context 'when class is frozen (< 2h away)' do
      let(:event) do
        create(:booking_event, booking: booking, status: "pending",
               occurrence: DateTime.new(2026, 3, 7, 12, 0, 0))
      end

      it 'marks event as failed' do
        travel_to Time.utc(2026, 3, 7, 10, 0, 0) do
          ClassBooker.call(event)
        end

        event.reload
        expect(event.status).to eq("failed")
        expect(event.debug_info).to include("zamrożona")
      end
    end

    context 'when seats are available' do
      let(:event) do
        create(:booking_event, booking: booking, status: "pending",
               occurrence: DateTime.new(2026, 3, 15, 18, 0, 0))
      end

      before do
        allow(api_client).to receive(:get_class_details)
          .with(class_id: 42)
          .and_return({ "BookingIndicator" => { "Available" => "5" } })
        allow(api_client).to receive(:book_class)
      end

      it 'books the class and marks event as booked' do
        travel_to Time.utc(2026, 3, 13, 17, 0, 10) do
          ClassBooker.call(event)
        end

        event.reload
        expect(event.status).to eq("booked")
        expect(api_client).to have_received(:book_class).with(class_id: 42, club_id: 7)
      end

      it 'creates next week event' do
        event # force creation before counting
        travel_to Time.utc(2026, 3, 13, 17, 0, 10) do
          expect { ClassBooker.call(event) }.to change(BookingEvent, :count).by(1)
        end

        next_event = booking.booking_events.order(:id).last
        expect(next_event.occurrence).to eq(event.occurrence + 1.week)
        expect(next_event.status).to eq("pending")
      end
    end

    context 'when no seats available' do
      let(:event) do
        create(:booking_event, booking: booking, status: "pending",
               occurrence: DateTime.new(2026, 3, 15, 18, 0, 0))
      end

      before do
        allow(api_client).to receive(:get_class_details)
          .with(class_id: 42)
          .and_return({ "BookingIndicator" => { "Available" => "0" } })
      end

      it 'reschedules the job in 30 minutes' do
        set_double = double("set")
        allow(ClassBookerJob).to receive(:set).and_return(set_double)
        allow(set_double).to receive(:perform_later)

        travel_to Time.utc(2026, 3, 13, 17, 0, 10) do
          ClassBooker.call(event)
        end

        event.reload
        expect(event.status).to eq("pending")
      end
    end

    context 'when a transient error occurs' do
      let(:event) do
        create(:booking_event, booking: booking, status: "pending",
               occurrence: DateTime.new(2026, 3, 15, 18, 0, 0))
      end

      before do
        allow(api_client).to receive(:get_class_details)
          .and_raise(RuntimeError, "SSL_read: connection reset")
        allow(ZdrofitClient).to receive(:rotate_proxy)
      end

      it 'raises TransientError and updates debug_info' do
        travel_to Time.utc(2026, 3, 13, 17, 0, 10) do
          expect { ClassBooker.call(event) }.to raise_error(ClassBooker::TransientError)
        end

        event.reload
        expect(event.debug_info).to include("transient")
        expect(event.status).to eq("pending")
      end

      it 'rotates proxy' do
        travel_to Time.utc(2026, 3, 13, 17, 0, 10) do
          ClassBooker.call(event) rescue nil
        end

        expect(ZdrofitClient).to have_received(:rotate_proxy)
      end
    end

    context 'when a permanent error occurs' do
      let(:event) do
        create(:booking_event, booking: booking, status: "pending",
               occurrence: DateTime.new(2026, 3, 15, 18, 0, 0))
      end

      before do
        allow(api_client).to receive(:get_class_details)
          .and_raise(RuntimeError, "Account suspended")
      end

      it 'marks event as failed and re-raises' do
        travel_to Time.utc(2026, 3, 13, 17, 0, 10) do
          expect { ClassBooker.call(event) }.to raise_error(RuntimeError, "Account suspended")
        end

        event.reload
        expect(event.status).to eq("failed")
        expect(event.debug_info).to eq("Account suspended")
      end
    end
  end
end
