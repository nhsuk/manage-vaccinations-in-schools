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

ActiveRecord::Schema[7.0].define(version: 2023_08_24_123840) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "batches", force: :cascade do |t|
    t.string "name"
    t.date "expiry"
    t.bigint "vaccine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vaccine_id"], name: "index_batches_on_vaccine_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaigns_vaccines", id: false, force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "vaccine_id", null: false
    t.index ["campaign_id", "vaccine_id"], name: "index_campaigns_vaccines_on_campaign_id_and_vaccine_id"
    t.index ["vaccine_id", "campaign_id"], name: "index_campaigns_vaccines_on_vaccine_id_and_campaign_id"
  end

  create_table "consent_forms", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "first_name"
    t.text "last_name"
    t.boolean "use_common_name"
    t.text "common_name"
    t.index ["session_id"], name: "index_consent_forms_on_session_id"
  end

  create_table "consents", force: :cascade do |t|
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
    t.integer "response"
    t.integer "reason_for_refusal"
    t.text "reason_for_refusal_other"
    t.integer "gp_response"
    t.text "gp_name"
    t.integer "route", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "health_questions"
    t.datetime "recorded_at"
    t.index ["campaign_id"], name: "index_consents_on_campaign_id"
    t.index ["patient_id"], name: "index_consents_on_patient_id"
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
    t.string "state"
    t.boolean "gillick_competent"
    t.text "gillick_competence_notes"
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
    t.integer "screening"
    t.integer "consent"
    t.integer "seen"
    t.text "parent_name"
    t.integer "parent_relationship"
    t.text "parent_relationship_other"
    t.text "parent_email"
    t.text "parent_phone"
    t.text "parent_info_source"
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
    t.integer "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "patient_session_id"
    t.index ["patient_session_id"], name: "index_triage_on_patient_session_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vaccination_records", force: :cascade do |t|
    t.bigint "patient_session_id", null: false
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivery_site"
    t.boolean "administered"
    t.integer "reason"
    t.bigint "batch_id"
    t.integer "delivery_method"
    t.index ["batch_id"], name: "index_vaccination_records_on_batch_id"
    t.index ["patient_session_id"], name: "index_vaccination_records_on_patient_session_id"
  end

  create_table "vaccines", force: :cascade do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "brand"
    t.integer "method"
    t.index ["type"], name: "index_vaccines_on_type", unique: true
  end

  add_foreign_key "batches", "vaccines"
  add_foreign_key "consent_forms", "sessions"
  add_foreign_key "consents", "campaigns"
  add_foreign_key "consents", "patients"
  add_foreign_key "health_questions", "vaccines"
  add_foreign_key "triage", "patient_sessions"
  add_foreign_key "vaccination_records", "batches"
  add_foreign_key "vaccination_records", "patient_sessions"
end
