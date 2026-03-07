FactoryBot.define do
  factory :booking do
    class_id { 1 }
    club_id { 1 }
    class_name { "FBW" }
    trainer_name { "Jan Kowalski" }
    zdrofit_user
  end
end
