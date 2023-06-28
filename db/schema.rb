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

ActiveRecord::Schema[7.0].define(version: 2023_06_28_144627) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "vaccine_id", null: false
    t.index ["vaccine_id"], name: "index_campaigns_on_vaccine_id"
  end

  create_table "consent_responses", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "campaign_id", null: false
    t.text "childs_name"
    t.text "childs_common_name"
    t.date "childs_dob"
    t.text "address_line_1"
    t.text "address_line_2"
    t.text "address_town"
    t.text "address_postcode"
    t.text "parent_name"
    t.integer "parent_relationship"
    t.text "parent_relationship_other"
    t.text "parent_email"
    t.text "parent_phone"
    t.integer "parent_contact_method"
    t.text "parent_contact_method_other"
    t.integer "consent"
    t.integer "reason_for_refusal"
    t.text "reason_for_refusal_other"
    t.integer "gp_response"
    t.text "gp_name"
    t.integer "route", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "health_questions"
    t.index ["campaign_id"], name: "index_consent_responses_on_campaign_id"
    t.index ["patient_id"], name: "index_consent_responses_on_patient_id"
  end

  create_table "health_questions", force: :cascade do |t|
    t.string "question"
    t.bigint "vaccine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vaccine_id"], name: "index_health_questions_on_vaccine_id"
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

  create_table "patient_sessions", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id", "session_id"], name: "index_patient_sessions_on_patient_id_and_session_id", unique: true
    t.index ["session_id", "patient_id"], name: "index_patient_sessions_on_session_id_and_patient_id", unique: true
  end

  create_table "patients", force: :cascade do |t|
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
    t.index ["nhs_number"], name: "index_patients_on_nhs_number", unique: true
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

  create_table "triage", force: :cascade do |t|
    t.bigint "campaign_id"
    t.bigint "patient_id"
    t.integer "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_triage_on_campaign_id"
    t.index ["patient_id"], name: "index_triage_on_patient_id"
  end

  create_table "vaccination_records", force: :cascade do |t|
    t.bigint "patient_session_id", null: false
    t.date "administered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_session_id"], name: "index_vaccination_records_on_patient_session_id"
  end

  create_table "vaccines", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_vaccines_on_name", unique: true
  end

  add_foreign_key "campaigns", "vaccines"
  add_foreign_key "consent_responses", "campaigns"
  add_foreign_key "consent_responses", "patients"
  add_foreign_key "health_questions", "vaccines"
  add_foreign_key "vaccination_records", "patient_sessions"
end
