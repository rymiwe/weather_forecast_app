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

ActiveRecord::Schema[7.1].define(version: 2025_04_09_223828) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "forecasts", force: :cascade do |t|
    t.string "address"
    t.string "zip_code"
    t.integer "current_temp"
    t.integer "high_temp"
    t.integer "low_temp"
    t.string "conditions"
    t.text "extended_forecast"
    t.datetime "queried_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queried_at"], name: "index_forecasts_on_queried_at"
    t.index ["zip_code", "queried_at"], name: "index_forecasts_on_zip_code_and_queried_at"
    t.index ["zip_code"], name: "index_forecasts_on_zip_code"
  end

end
