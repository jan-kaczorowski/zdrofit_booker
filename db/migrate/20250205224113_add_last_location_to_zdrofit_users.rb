class AddLastLocationToZdrofitUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :zdrofit_users, :last_city_id, :string
    add_column :zdrofit_users, :last_club_id, :integer
  end
end
