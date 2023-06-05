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

ActiveRecord::Schema[7.0].define(version: 2023_06_05_104145) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "children", force: :cascade do |t|
    t.date "dob"
    t.bigint "nhs_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sex"
    t.text "first_name"
    t.text "last_name"
    t.text "preferred_name"
    t.integer "gp"
    t.integer "screening"
    t.integer "consent"
    t.integer "seen"
    t.index ["nhs_number"], name: "index_children_on_nhs_number", unique: true
  end

  create_table "children_sessions", id: false, force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "session_id"], name: "index_children_sessions_on_child_id_and_session_id", unique: true
    t.index ["session_id", "child_id"], name: "index_children_sessions_on_session_id_and_child_id", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.text "name"
    t.text "address"
    t.text "locality"
    t.text "town"
    t.text "county"
    t.text "postcode"
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "offline_passwords", force: :cascade do |t|
    t.string "password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "date"
    t.bigint "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name", null: false
    t.bigint "campaign_id", null: false
    t.index ["campaign_id"], name: "index_sessions_on_campaign_id"
  end

end
