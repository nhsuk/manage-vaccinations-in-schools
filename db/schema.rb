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

ActiveRecord::Schema[7.0].define(version: 2023_01_15_124728) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.text "title"
    t.datetime "date"
    t.text "location_type"
    t.integer "location_id"
    t.integer "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaigns_children", id: false, force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "child_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "child_id"], name: "index_campaigns_children_on_campaign_id_and_child_id"
    t.index ["child_id", "campaign_id"], name: "index_campaigns_children_on_child_id_and_campaign_id"
  end

  create_table "children", force: :cascade do |t|
    t.date "dob"
    t.decimal "nhs_number"
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
  end

  create_table "schools", force: :cascade do |t|
    t.decimal "urn"
    t.text "name"
    t.text "address"
    t.text "locality"
    t.text "town"
    t.text "county"
    t.text "postcode"
    t.decimal "minimum_age"
    t.decimal "maximum_age"
    t.text "url"
    t.integer "phase"
    t.text "type"
    t.text "detailed_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
