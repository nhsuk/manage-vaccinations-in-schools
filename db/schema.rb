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

ActiveRecord::Schema[7.1].define(version: 2024_08_15_114839) do
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
    t.string "name", null: false
    t.date "expiry", null: false
    t.bigint "vaccine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vaccine_id"], name: "index_batches_on_vaccine_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id", null: false
    t.integer "academic_year", null: false
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: false, null: false
    t.string "type", null: false
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
    t.date "date_of_birth"
    t.integer "response"
    t.integer "reason"
    t.text "reason_notes"
    t.boolean "contact_injection"
    t.string "gp_name"
    t.integer "gp_response"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_town"
    t.string "address_postcode"
    t.jsonb "health_answers", default: [], null: false
    t.bigint "consent_id"
    t.bigint "parent_id"
    t.index ["consent_id"], name: "index_consent_forms_on_consent_id"
    t.index ["parent_id"], name: "index_consent_forms_on_parent_id"
    t.index ["session_id"], name: "index_consent_forms_on_session_id"
  end

  create_table "consents", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "campaign_id", null: false
    t.integer "response"
    t.integer "reason_for_refusal"
    t.text "reason_for_refusal_notes"
    t.integer "route"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "recorded_at"
    t.jsonb "health_answers", default: []
    t.bigint "recorded_by_user_id"
    t.bigint "parent_id"
    t.index ["campaign_id"], name: "index_consents_on_campaign_id"
    t.index ["parent_id"], name: "index_consents_on_parent_id"
    t.index ["patient_id"], name: "index_consents_on_patient_id"
    t.index ["recorded_by_user_id"], name: "index_consents_on_recorded_by_user_id"
  end

  create_table "dps_exports", force: :cascade do |t|
    t.string "message_id"
    t.string "status", default: "pending", null: false
    t.string "filename", null: false
    t.datetime "sent_at", precision: nil
    t.bigint "campaign_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_dps_exports_on_campaign_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "gillick_assessments", force: :cascade do |t|
    t.boolean "gillick_competent"
    t.text "notes"
    t.datetime "recorded_at"
    t.bigint "assessor_user_id", null: false
    t.bigint "patient_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessor_user_id"], name: "index_gillick_assessments_on_assessor_user_id"
    t.index ["patient_session_id"], name: "index_gillick_assessments_on_patient_session_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "health_questions", force: :cascade do |t|
    t.string "question"
    t.bigint "vaccine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hint"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "follow_up_question_id"
    t.bigint "next_question_id"
    t.index ["follow_up_question_id"], name: "index_health_questions_on_follow_up_question_id"
    t.index ["next_question_id"], name: "index_health_questions_on_next_question_id"
    t.index ["vaccine_id"], name: "index_health_questions_on_vaccine_id"
  end

  create_table "immunisation_imports", force: :cascade do |t|
    t.text "csv", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "campaign_id", null: false
    t.index ["campaign_id"], name: "index_immunisation_imports_on_campaign_id"
    t.index ["user_id"], name: "index_immunisation_imports_on_user_id"
  end

  create_table "locations", force: :cascade do |t|
    t.text "name", null: false
    t.text "address"
    t.text "locality"
    t.text "town"
    t.text "county"
    t.text "postcode"
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "urn"
    t.bigint "imported_from_id"
    t.integer "type", null: false
    t.string "ods_code"
    t.index ["imported_from_id"], name: "index_locations_on_imported_from_id"
    t.index ["ods_code"], name: "index_locations_on_ods_code", unique: true
    t.index ["urn"], name: "index_locations_on_urn", unique: true
  end

  create_table "offline_passwords", force: :cascade do |t|
    t.string "password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parents", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.integer "relationship"
    t.string "relationship_other"
    t.integer "contact_method"
    t.text "contact_method_other"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "recorded_at"
  end

  create_table "patient_sessions", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.bigint "created_by_user_id"
    t.index ["created_by_user_id"], name: "index_patient_sessions_on_created_by_user_id"
    t.index ["patient_id", "session_id"], name: "index_patient_sessions_on_patient_id_and_session_id", unique: true
    t.index ["session_id", "patient_id"], name: "index_patient_sessions_on_session_id_and_patient_id", unique: true
  end

  create_table "patients", force: :cascade do |t|
    t.date "date_of_birth"
    t.string "nhs_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "common_name"
    t.bigint "school_id"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_town"
    t.string "address_postcode"
    t.datetime "sent_consent_at"
    t.datetime "sent_reminder_at"
    t.datetime "session_reminder_sent_at"
    t.bigint "parent_id"
    t.bigint "imported_from_id"
    t.integer "gender_code", default: 0, null: false
    t.boolean "home_educated"
    t.index ["imported_from_id"], name: "index_patients_on_imported_from_id"
    t.index ["nhs_number"], name: "index_patients_on_nhs_number", unique: true
    t.index ["parent_id"], name: "index_patients_on_parent_id"
    t.index ["school_id"], name: "index_patients_on_school_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.date "date"
    t.bigint "location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "campaign_id"
    t.boolean "draft", default: false
    t.date "send_consent_at"
    t.date "send_reminders_at"
    t.date "close_consent_at"
    t.integer "time_of_day"
    t.bigint "imported_from_id"
    t.index ["campaign_id"], name: "index_sessions_on_campaign_id"
    t.index ["imported_from_id"], name: "index_sessions_on_imported_from_id"
  end

  create_table "teams", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "privacy_policy_url"
    t.string "ods_code", null: false
    t.string "reply_to_id"
    t.string "phone"
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["ods_code"], name: "index_teams_on_ods_code", unique: true
  end

  create_table "teams_users", id: false, force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.index ["team_id", "user_id"], name: "index_teams_users_on_team_id_and_user_id"
    t.index ["user_id", "team_id"], name: "index_teams_users_on_user_id_and_team_id"
  end

  create_table "triage", force: :cascade do |t|
    t.integer "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "patient_session_id"
    t.bigint "user_id"
    t.index ["patient_session_id"], name: "index_triage_on_patient_session_id"
    t.index ["user_id"], name: "index_triage_on_user_id"
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
    t.string "full_name"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "registration"
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
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
    t.bigint "user_id"
    t.text "notes"
    t.bigint "vaccine_id"
    t.bigint "imported_from_id"
    t.datetime "exported_to_dps_at"
    t.integer "dose_sequence", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["batch_id"], name: "index_vaccination_records_on_batch_id"
    t.index ["imported_from_id"], name: "index_vaccination_records_on_imported_from_id"
    t.index ["patient_session_id"], name: "index_vaccination_records_on_patient_session_id"
    t.index ["user_id"], name: "index_vaccination_records_on_user_id"
    t.index ["vaccine_id"], name: "index_vaccination_records_on_vaccine_id"
  end

  create_table "vaccines", force: :cascade do |t|
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "brand", null: false
    t.integer "method", null: false
    t.text "manufacturer", null: false
    t.text "gtin"
    t.decimal "dose", null: false
    t.string "snomed_product_code", null: false
    t.string "snomed_product_term", null: false
    t.text "nivs_name", null: false
    t.boolean "discontinued", default: false, null: false
    t.index ["gtin"], name: "index_vaccines_on_gtin", unique: true
    t.index ["manufacturer", "brand"], name: "index_vaccines_on_manufacturer_and_brand", unique: true
    t.index ["nivs_name"], name: "index_vaccines_on_nivs_name", unique: true
    t.index ["snomed_product_code"], name: "index_vaccines_on_snomed_product_code", unique: true
    t.index ["snomed_product_term"], name: "index_vaccines_on_snomed_product_term", unique: true
  end

  add_foreign_key "batches", "vaccines"
  add_foreign_key "campaigns", "teams"
  add_foreign_key "consent_forms", "consents"
  add_foreign_key "consent_forms", "parents"
  add_foreign_key "consent_forms", "sessions"
  add_foreign_key "consents", "campaigns"
  add_foreign_key "consents", "parents"
  add_foreign_key "consents", "patients"
  add_foreign_key "consents", "users", column: "recorded_by_user_id"
  add_foreign_key "dps_exports", "campaigns"
  add_foreign_key "gillick_assessments", "patient_sessions"
  add_foreign_key "gillick_assessments", "users", column: "assessor_user_id"
  add_foreign_key "health_questions", "health_questions", column: "follow_up_question_id"
  add_foreign_key "health_questions", "health_questions", column: "next_question_id"
  add_foreign_key "health_questions", "vaccines"
  add_foreign_key "immunisation_imports", "campaigns"
  add_foreign_key "immunisation_imports", "users"
  add_foreign_key "locations", "immunisation_imports", column: "imported_from_id"
  add_foreign_key "patient_sessions", "users", column: "created_by_user_id"
  add_foreign_key "patients", "immunisation_imports", column: "imported_from_id"
  add_foreign_key "patients", "locations", column: "school_id"
  add_foreign_key "patients", "parents"
  add_foreign_key "sessions", "immunisation_imports", column: "imported_from_id"
  add_foreign_key "triage", "patient_sessions"
  add_foreign_key "triage", "users"
  add_foreign_key "vaccination_records", "batches"
  add_foreign_key "vaccination_records", "immunisation_imports", column: "imported_from_id"
  add_foreign_key "vaccination_records", "patient_sessions"
  add_foreign_key "vaccination_records", "users"
  add_foreign_key "vaccination_records", "vaccines"
end
