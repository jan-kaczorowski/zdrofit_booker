FactoryBot.define do
  factory :booking_event do
    booking
    occurrence { DateTime.new(2026, 1, 20, 18, 30, 0) }
    status { "pending" }
  end
end
