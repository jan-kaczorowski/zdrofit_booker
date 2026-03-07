class ZdrofitUser < ApplicationRecord
  encrypts :email, deterministic: true
  encrypts :pass, deterministic: true
  encrypts :auth_token

  has_many :bookings

  # Token validity buffer (refresh 30 min before actual expiry)
  TOKEN_REFRESH_BUFFER = 30.minutes

  def zdrofit_api_client
    client = ZdrofitClient::Client.new(email, pass)

    if valid_cached_token?
      # Reuse cached token
      client.set_auth_token(auth_token)
      Rails.logger.info "[ZdrofitUser] Reusing cached token for user #{id}"
    else
      # Login and cache the new token
      client.login
      cache_auth_token(client.auth_token, client.token_expires_at)
      Rails.logger.info "[ZdrofitUser] Fresh login for user #{id}, token cached until #{auth_token_expires_at}"
    end

    client
  end

  def update_last_location(city_id:, club_id:)
    update(
      last_city_id: city_id,
      last_club_id: club_id
    )
  end

  def clear_cached_token!
    update(auth_token: nil, auth_token_expires_at: nil)
  end

  private

  def valid_cached_token?
    auth_token.present? &&
      auth_token_expires_at.present? &&
      auth_token_expires_at > Time.current + TOKEN_REFRESH_BUFFER
  end

  def cache_auth_token(token, expires_at)
    update(
      auth_token: token,
      auth_token_expires_at: expires_at
    )
  end
end
