class CreateZdrofitUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :zdrofit_users do |t|
      t.string :email
      t.string :pass

      t.timestamps
    end
  end
end
