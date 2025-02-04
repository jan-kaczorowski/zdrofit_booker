class ZdrofitUser < ApplicationRecord
  encrypts :email, deterministic: true
  encrypts :pass, deterministic: true

  has_many :zdrofit_class_bookings

  attr_accessor :zdrofit_client

  def zdrofit_api_client
    client = ZdrofitClient::Client.new(email, pass)
    client.login
    client
  end

  def update_last_location(city_id:, club_id:)
    update(
      last_city_id: city_id,
      last_club_id: club_id
    )
  end
end
