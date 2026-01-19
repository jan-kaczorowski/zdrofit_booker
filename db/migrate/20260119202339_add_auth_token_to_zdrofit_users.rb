class AddAuthTokenToZdrofitUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :zdrofit_users, :auth_token, :text
    add_column :zdrofit_users, :auth_token_expires_at, :datetime
  end
end
