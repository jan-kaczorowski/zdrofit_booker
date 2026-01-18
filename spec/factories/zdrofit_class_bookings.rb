FactoryBot.define do
  factory :zdrofit_class_booking do
    class_id { 1 }
    club_id { 1 }
    next_occurrence { DateTime.new(2026, 1, 20, 18, 30, 0) }
    zdrofit_user
  end
end
