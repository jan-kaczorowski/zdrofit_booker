# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_02_07_221640) do
  create_table "zdrofit_class_bookings", force: :cascade do |t|
    t.integer "class_id"
    t.integer "club_id"
    t.datetime "next_occurrence"
    t.integer "zdrofit_user_id", null: false
    t.string "status"
    t.string "mode"
    t.string "class_name"
    t.string "trainer_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zdrofit_user_id"], name: "index_zdrofit_class_bookings_on_zdrofit_user_id"
  end

  create_table "zdrofit_users", force: :cascade do |t|
    t.string "email"
    t.string "pass"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "last_city_id"
    t.integer "last_club_id"
  end

  add_foreign_key "zdrofit_class_bookings", "zdrofit_users"
end
