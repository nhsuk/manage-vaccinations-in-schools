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

ActiveRecord::Schema[8.0].define(version: 2025_07_16_151841) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "access_log_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "patient_id", null: false
    t.integer "controller", null: false
    t.integer "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_access_log_entries_on_patient_id"
    t.index ["user_id"], name: "index_access_log_entries_on_user_id"
  end

  create_table "active_record_sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_active_record_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_active_record_sessions_on_updated_at"
  end

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
    t.date "expiry"
    t.bigint "vaccine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organisation_id", null: false
    t.datetime "archived_at"
    t.index ["organisation_id", "name", "expiry", "vaccine_id"], name: "idx_on_organisation_id_name_expiry_vaccine_id_6d9ae30338", unique: true
    t.index ["vaccine_id"], name: "index_batches_on_vaccine_id"
  end

  create_table "batches_immunisation_imports", id: false, force: :cascade do |t|
    t.bigint "immunisation_import_id", null: false
    t.bigint "batch_id", null: false
    t.index ["immunisation_import_id", "batch_id"], name: "idx_on_immunisation_import_id_batch_id_d039b76103", unique: true
  end

  create_table "class_imports", force: :cascade do |t|
    t.integer "changed_record_count"
    t.text "csv_data"
    t.text "csv_filename"
    t.datetime "csv_removed_at"
    t.integer "exact_duplicate_record_count"
    t.integer "new_record_count"
    t.datetime "processed_at"
    t.jsonb "serialized_errors"
    t.integer "status", default: 0, null: false
    t.bigint "organisation_id", null: false
    t.bigint "session_id", null: false
    t.bigint "uploaded_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rows_count"
    t.integer "year_groups", default: [], null: false, array: true
    t.index ["organisation_id"], name: "index_class_imports_on_organisation_id"
    t.index ["session_id"], name: "index_class_imports_on_session_id"
    t.index ["uploaded_by_user_id"], name: "index_class_imports_on_uploaded_by_user_id"
  end

  create_table "class_imports_parent_relationships", id: false, force: :cascade do |t|
    t.bigint "class_import_id", null: false
    t.bigint "parent_relationship_id", null: false
    t.index ["class_import_id", "parent_relationship_id"], name: "idx_on_class_import_id_parent_relationship_id_8225058195", unique: true
  end

  create_table "class_imports_parents", id: false, force: :cascade do |t|
    t.bigint "class_import_id", null: false
    t.bigint "parent_id", null: false
    t.index ["class_import_id", "parent_id"], name: "index_class_imports_parents_on_class_import_id_and_parent_id", unique: true
  end

  create_table "class_imports_patients", id: false, force: :cascade do |t|
    t.bigint "class_import_id", null: false
    t.bigint "patient_id", null: false
    t.index ["class_import_id", "patient_id"], name: "index_class_imports_patients_on_class_import_id_and_patient_id", unique: true
  end

  create_table "cohort_imports", force: :cascade do |t|
    t.datetime "csv_removed_at"
    t.datetime "processed_at"
    t.text "csv_data"
    t.text "csv_filename"
    t.integer "new_record_count"
    t.integer "exact_duplicate_record_count"
    t.bigint "uploaded_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "changed_record_count"
    t.bigint "organisation_id", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "serialized_errors"
    t.integer "rows_count"
    t.index ["organisation_id"], name: "index_cohort_imports_on_organisation_id"
    t.index ["uploaded_by_user_id"], name: "index_cohort_imports_on_uploaded_by_user_id"
  end

  create_table "cohort_imports_parent_relationships", id: false, force: :cascade do |t|
    t.bigint "cohort_import_id", null: false
    t.bigint "parent_relationship_id", null: false
    t.index ["cohort_import_id", "parent_relationship_id"], name: "idx_on_cohort_import_id_parent_relationship_id_c65e20d1f8", unique: true
  end

  create_table "cohort_imports_parents", id: false, force: :cascade do |t|
    t.bigint "cohort_import_id", null: false
    t.bigint "parent_id", null: false
    t.index ["cohort_import_id", "parent_id"], name: "index_cohort_imports_parents_on_cohort_import_id_and_parent_id", unique: true
  end

  create_table "cohort_imports_patients", id: false, force: :cascade do |t|
    t.bigint "cohort_import_id", null: false
    t.bigint "patient_id", null: false
    t.index ["cohort_import_id", "patient_id"], name: "idx_on_cohort_import_id_patient_id_7864d1a8b0", unique: true
  end

  create_table "consent_form_programmes", force: :cascade do |t|
    t.bigint "programme_id", null: false
    t.bigint "consent_form_id", null: false
    t.integer "response"
    t.integer "vaccine_methods", default: [], null: false, array: true
    t.index ["consent_form_id"], name: "index_consent_form_programmes_on_consent_form_id"
    t.index ["programme_id", "consent_form_id"], name: "idx_on_programme_id_consent_form_id_2113cb7f37", unique: true
  end

  create_table "consent_forms", force: :cascade do |t|
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "given_name"
    t.text "family_name"
    t.boolean "use_preferred_name"
    t.date "date_of_birth"
    t.integer "reason"
    t.text "reason_notes"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_town"
    t.string "address_postcode"
    t.jsonb "health_answers", default: [], null: false
    t.bigint "consent_id"
    t.string "parent_contact_method_other_details"
    t.string "parent_contact_method_type"
    t.string "parent_email"
    t.string "parent_full_name"
    t.string "parent_phone"
    t.string "parent_relationship_other_name"
    t.string "parent_relationship_type"
    t.boolean "parent_phone_receive_updates", default: false, null: false
    t.boolean "school_confirmed"
    t.bigint "location_id", null: false
    t.bigint "organisation_id", null: false
    t.bigint "school_id"
    t.string "preferred_given_name"
    t.string "preferred_family_name"
    t.integer "education_setting"
    t.string "nhs_number"
    t.datetime "archived_at"
    t.text "notes", default: "", null: false
    t.index ["consent_id"], name: "index_consent_forms_on_consent_id"
    t.index ["location_id"], name: "index_consent_forms_on_location_id"
    t.index ["nhs_number"], name: "index_consent_forms_on_nhs_number"
    t.index ["organisation_id"], name: "index_consent_forms_on_organisation_id"
    t.index ["school_id"], name: "index_consent_forms_on_school_id"
  end

  create_table "consent_notification_programmes", force: :cascade do |t|
    t.bigint "programme_id", null: false
    t.bigint "consent_notification_id", null: false
    t.index ["consent_notification_id"], name: "idx_on_consent_notification_id_bde310472f"
    t.index ["programme_id", "consent_notification_id"], name: "idx_on_programme_id_consent_notification_id_e185bde5f5", unique: true
  end

  create_table "consent_notifications", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.datetime "sent_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "type", null: false
    t.bigint "sent_by_user_id"
    t.bigint "session_id", null: false
    t.index ["patient_id"], name: "index_consent_notifications_on_patient_id"
    t.index ["sent_by_user_id"], name: "index_consent_notifications_on_sent_by_user_id"
    t.index ["session_id"], name: "index_consent_notifications_on_session_id"
  end

  create_table "consents", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "response", null: false
    t.integer "reason_for_refusal"
    t.text "notes", default: "", null: false
    t.integer "route", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "health_answers", default: [], null: false
    t.bigint "recorded_by_user_id"
    t.bigint "parent_id"
    t.bigint "organisation_id", null: false
    t.datetime "withdrawn_at"
    t.datetime "invalidated_at"
    t.boolean "notify_parents"
    t.datetime "submitted_at", null: false
    t.integer "vaccine_methods", default: [], null: false, array: true
    t.index ["organisation_id"], name: "index_consents_on_organisation_id"
    t.index ["parent_id"], name: "index_consents_on_parent_id"
    t.index ["patient_id"], name: "index_consents_on_patient_id"
    t.index ["programme_id"], name: "index_consents_on_programme_id"
    t.index ["recorded_by_user_id"], name: "index_consents_on_recorded_by_user_id"
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
    t.text "notes", default: "", null: false
    t.bigint "performed_by_user_id", null: false
    t.bigint "patient_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "knows_vaccination", null: false
    t.boolean "knows_disease", null: false
    t.boolean "knows_consequences", null: false
    t.boolean "knows_delivery", null: false
    t.boolean "knows_side_effects", null: false
    t.bigint "programme_id", null: false
    t.index ["patient_session_id"], name: "index_gillick_assessments_on_patient_session_id"
    t.index ["performed_by_user_id"], name: "index_gillick_assessments_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_gillick_assessments_on_programme_id"
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
    t.string "title", null: false
    t.bigint "vaccine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hint"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "follow_up_question_id"
    t.bigint "next_question_id"
    t.boolean "would_require_triage", default: true, null: false
    t.string "give_details_hint"
    t.index ["follow_up_question_id"], name: "index_health_questions_on_follow_up_question_id"
    t.index ["next_question_id"], name: "index_health_questions_on_next_question_id"
    t.index ["vaccine_id"], name: "index_health_questions_on_vaccine_id"
  end

  create_table "identity_checks", force: :cascade do |t|
    t.boolean "confirmed_by_patient", null: false
    t.string "confirmed_by_other_name", default: "", null: false
    t.string "confirmed_by_other_relationship", default: "", null: false
    t.bigint "vaccination_record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vaccination_record_id"], name: "index_identity_checks_on_vaccination_record_id"
  end

  create_table "immunisation_imports", force: :cascade do |t|
    t.text "csv_data"
    t.bigint "uploaded_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "processed_at"
    t.integer "new_record_count"
    t.integer "exact_duplicate_record_count"
    t.text "csv_filename", null: false
    t.datetime "csv_removed_at"
    t.integer "changed_record_count"
    t.bigint "organisation_id", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "serialized_errors"
    t.integer "rows_count"
    t.index ["organisation_id"], name: "index_immunisation_imports_on_organisation_id"
    t.index ["uploaded_by_user_id"], name: "index_immunisation_imports_on_uploaded_by_user_id"
  end

  create_table "immunisation_imports_patient_sessions", id: false, force: :cascade do |t|
    t.bigint "immunisation_import_id", null: false
    t.bigint "patient_session_id", null: false
    t.index ["immunisation_import_id", "patient_session_id"], name: "idx_on_immunisation_import_id_patient_session_id_b5003c646e", unique: true
  end

  create_table "immunisation_imports_patients", id: false, force: :cascade do |t|
    t.bigint "immunisation_import_id", null: false
    t.bigint "patient_id", null: false
    t.index ["immunisation_import_id", "patient_id"], name: "idx_on_immunisation_import_id_patient_id_6dc58d875d", unique: true
  end

  create_table "immunisation_imports_sessions", id: false, force: :cascade do |t|
    t.bigint "immunisation_import_id", null: false
    t.bigint "session_id", null: false
    t.index ["immunisation_import_id", "session_id"], name: "idx_on_immunisation_import_id_session_id_f8b87b9417", unique: true
  end

  create_table "immunisation_imports_vaccination_records", id: false, force: :cascade do |t|
    t.bigint "immunisation_import_id", null: false
    t.bigint "vaccination_record_id", null: false
    t.index ["immunisation_import_id", "vaccination_record_id"], name: "idx_on_immunisation_import_id_vaccination_record_id_588e859772", unique: true
  end

  create_table "location_programme_year_groups", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.bigint "programme_id", null: false
    t.integer "year_group", null: false
    t.index ["location_id", "programme_id", "year_group"], name: "idx_on_location_id_programme_id_year_group_4bee220488", unique: true
    t.index ["location_id"], name: "index_location_programme_year_groups_on_location_id"
    t.index ["programme_id"], name: "index_location_programme_year_groups_on_programme_id"
  end

  create_table "locations", force: :cascade do |t|
    t.text "name", null: false
    t.text "address_line_1"
    t.text "address_line_2"
    t.text "address_town"
    t.text "address_postcode"
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "urn"
    t.integer "type", null: false
    t.string "ods_code"
    t.integer "year_groups", default: [], null: false, array: true
    t.bigint "team_id"
    t.integer "gias_local_authority_code"
    t.integer "gias_establishment_number"
    t.integer "status", default: 0, null: false
    t.index ["ods_code"], name: "index_locations_on_ods_code", unique: true
    t.index ["team_id"], name: "index_locations_on_team_id"
    t.index ["urn"], name: "index_locations_on_urn", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "created_by_user_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "session_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_notes_on_created_by_user_id"
    t.index ["patient_id"], name: "index_notes_on_patient_id"
    t.index ["session_id"], name: "index_notes_on_session_id"
  end

  create_table "notify_log_entries", force: :cascade do |t|
    t.integer "type", null: false
    t.uuid "template_id", null: false
    t.datetime "created_at", null: false
    t.bigint "consent_form_id"
    t.bigint "patient_id"
    t.bigint "sent_by_user_id"
    t.uuid "delivery_id"
    t.integer "delivery_status", default: 0, null: false
    t.bigint "parent_id"
    t.string "recipient_deterministic"
    t.string "recipient", null: false
    t.integer "programme_ids", default: [], null: false, array: true
    t.index ["consent_form_id"], name: "index_notify_log_entries_on_consent_form_id"
    t.index ["delivery_id"], name: "index_notify_log_entries_on_delivery_id"
    t.index ["parent_id"], name: "index_notify_log_entries_on_parent_id"
    t.index ["patient_id"], name: "index_notify_log_entries_on_patient_id"
    t.index ["sent_by_user_id"], name: "index_notify_log_entries_on_sent_by_user_id"
  end

  create_table "offline_passwords", force: :cascade do |t|
    t.string "password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organisation_programmes", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "programme_id", null: false
    t.index ["organisation_id", "programme_id"], name: "idx_on_organisation_id_programme_id_892684ca8e", unique: true
    t.index ["programme_id"], name: "index_organisation_programmes_on_programme_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "privacy_policy_url", null: false
    t.string "ods_code", null: false
    t.uuid "reply_to_id"
    t.string "phone"
    t.integer "days_before_consent_requests", default: 21, null: false
    t.integer "days_before_consent_reminders", default: 7, null: false
    t.integer "days_before_invitations", default: 21, null: false
    t.string "careplus_venue_code", null: false
    t.string "privacy_notice_url", null: false
    t.string "phone_instructions"
    t.index ["name"], name: "index_organisations_on_name", unique: true
    t.index ["ods_code"], name: "index_organisations_on_ods_code", unique: true
  end

  create_table "organisations_users", id: false, force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.bigint "user_id", null: false
    t.index ["organisation_id", "user_id"], name: "index_organisations_users_on_organisation_id_and_user_id"
    t.index ["user_id", "organisation_id"], name: "index_organisations_users_on_user_id_and_organisation_id"
  end

  create_table "parent_relationships", force: :cascade do |t|
    t.bigint "parent_id", null: false
    t.bigint "patient_id", null: false
    t.string "type", null: false
    t.string "other_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "patient_id"], name: "index_parent_relationships_on_parent_id_and_patient_id", unique: true
    t.index ["patient_id"], name: "index_parent_relationships_on_patient_id"
  end

  create_table "parents", force: :cascade do |t|
    t.string "full_name"
    t.string "email"
    t.string "phone"
    t.text "contact_method_other_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contact_method_type"
    t.boolean "phone_receive_updates", default: false, null: false
    t.index ["email"], name: "index_parents_on_email"
  end

  create_table "patient_consent_statuses", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "vaccine_methods", default: [], null: false, array: true
    t.index ["patient_id", "programme_id"], name: "index_patient_consent_statuses_on_patient_id_and_programme_id", unique: true
    t.index ["status"], name: "index_patient_consent_statuses_on_status"
  end

  create_table "patient_session_registration_statuses", force: :cascade do |t|
    t.bigint "patient_session_id", null: false
    t.integer "status", default: 0, null: false
    t.index ["patient_session_id"], name: "idx_on_patient_session_id_438fc21144", unique: true
    t.index ["status"], name: "index_patient_session_registration_statuses_on_status"
  end

  create_table "patient_session_session_statuses", force: :cascade do |t|
    t.bigint "patient_session_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.index ["patient_session_id", "programme_id"], name: "idx_on_patient_session_id_programme_id_8777f5ba39", unique: true
    t.index ["status"], name: "index_patient_session_session_statuses_on_status"
  end

  create_table "patient_sessions", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id", "session_id"], name: "index_patient_sessions_on_patient_id_and_session_id", unique: true
    t.index ["session_id"], name: "index_patient_sessions_on_session_id"
  end

  create_table "patient_specific_directions", force: :cascade do |t|
    t.bigint "created_by_user_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.bigint "vaccine_id", null: false
    t.integer "vaccine_method", null: false
    t.integer "delivery_site", null: false
    t.boolean "full_dose", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_patient_specific_directions_on_created_by_user_id"
    t.index ["patient_id"], name: "index_patient_specific_directions_on_patient_id"
    t.index ["programme_id"], name: "index_patient_specific_directions_on_programme_id"
    t.index ["vaccine_id"], name: "index_patient_specific_directions_on_vaccine_id"
  end

  create_table "patient_triage_statuses", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "vaccine_method"
    t.index ["patient_id", "programme_id"], name: "index_patient_triage_statuses_on_patient_id_and_programme_id", unique: true
    t.index ["status"], name: "index_patient_triage_statuses_on_status"
  end

  create_table "patient_vaccination_statuses", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.index ["patient_id", "programme_id"], name: "idx_on_patient_id_programme_id_e876faade2", unique: true
    t.index ["status"], name: "index_patient_vaccination_statuses_on_status"
  end

  create_table "patients", force: :cascade do |t|
    t.date "date_of_birth", null: false
    t.string "nhs_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "given_name", null: false
    t.string "family_name", null: false
    t.bigint "school_id"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_town"
    t.string "address_postcode"
    t.integer "gender_code", default: 0, null: false
    t.boolean "home_educated"
    t.jsonb "pending_changes", default: {}, null: false
    t.string "registration"
    t.date "date_of_death"
    t.datetime "date_of_death_recorded_at"
    t.datetime "restricted_at"
    t.datetime "invalidated_at"
    t.string "preferred_given_name"
    t.string "preferred_family_name"
    t.datetime "updated_from_pds_at"
    t.bigint "gp_practice_id"
    t.integer "birth_academic_year", null: false
    t.index ["family_name", "given_name"], name: "index_patients_on_names_family_first"
    t.index ["family_name"], name: "index_patients_on_family_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["given_name", "family_name"], name: "index_patients_on_names_given_first"
    t.index ["given_name"], name: "index_patients_on_given_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["gp_practice_id"], name: "index_patients_on_gp_practice_id"
    t.index ["nhs_number"], name: "index_patients_on_nhs_number", unique: true
    t.index ["school_id"], name: "index_patients_on_school_id"
  end

  create_table "pre_screenings", force: :cascade do |t|
    t.bigint "patient_session_id", null: false
    t.bigint "performed_by_user_id", null: false
    t.text "notes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "programme_id", null: false
    t.index ["patient_session_id"], name: "index_pre_screenings_on_patient_session_id"
    t.index ["performed_by_user_id"], name: "index_pre_screenings_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_pre_screenings_on_programme_id"
  end

  create_table "programmes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.index ["type"], name: "index_programmes_on_type", unique: true
  end

  create_table "school_move_log_entries", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "user_id"
    t.bigint "school_id"
    t.boolean "home_educated"
    t.datetime "created_at", null: false
    t.index ["patient_id"], name: "index_school_move_log_entries_on_patient_id"
    t.index ["school_id"], name: "index_school_move_log_entries_on_school_id"
    t.index ["user_id"], name: "index_school_move_log_entries_on_user_id"
  end

  create_table "school_moves", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.integer "source", null: false
    t.bigint "school_id"
    t.bigint "organisation_id"
    t.boolean "home_educated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_school_moves_on_organisation_id"
    t.index ["patient_id", "home_educated", "organisation_id"], name: "idx_on_patient_id_home_educated_organisation_id_7c1b5f5066", unique: true
    t.index ["patient_id", "school_id"], name: "index_school_moves_on_patient_id_and_school_id", unique: true
    t.index ["school_id"], name: "index_school_moves_on_school_id"
  end

  create_table "session_attendances", force: :cascade do |t|
    t.bigint "patient_session_id", null: false
    t.bigint "session_date_id", null: false
    t.boolean "attending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_session_id", "session_date_id"], name: "idx_on_patient_session_id_session_date_id_be8bd21ddf", unique: true
    t.index ["session_date_id"], name: "index_session_attendances_on_session_date_id"
  end

  create_table "session_dates", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.date "value", null: false
    t.index ["session_id", "value"], name: "index_session_dates_on_session_id_and_value", unique: true
  end

  create_table "session_notifications", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "session_id", null: false
    t.date "session_date", null: false
    t.datetime "sent_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "type", null: false
    t.bigint "sent_by_user_id"
    t.index ["patient_id", "session_id", "session_date"], name: "idx_on_patient_id_session_id_session_date_f7f30a3aa3"
    t.index ["sent_by_user_id"], name: "index_session_notifications_on_sent_by_user_id"
    t.index ["session_id"], name: "index_session_notifications_on_session_id"
  end

  create_table "session_programmes", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "programme_id", null: false
    t.index ["programme_id"], name: "index_session_programmes_on_programme_id"
    t.index ["session_id", "programme_id"], name: "index_session_programmes_on_session_id_and_programme_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "send_consent_requests_at"
    t.bigint "organisation_id", null: false
    t.integer "academic_year", null: false
    t.integer "days_before_consent_reminders"
    t.string "slug", null: false
    t.date "send_invitations_at"
    t.index ["location_id"], name: "index_sessions_on_location_id"
    t.index ["organisation_id", "location_id"], name: "index_sessions_on_organisation_id_and_location_id"
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "reply_to_id"
    t.string "phone_instructions"
    t.index ["organisation_id", "name"], name: "index_teams_on_organisation_id_and_name", unique: true
  end

  create_table "triage", force: :cascade do |t|
    t.integer "status", null: false
    t.text "notes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "performed_by_user_id", null: false
    t.bigint "programme_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "organisation_id", null: false
    t.datetime "invalidated_at"
    t.integer "vaccine_method"
    t.index ["organisation_id"], name: "index_triage_on_organisation_id"
    t.index ["patient_id"], name: "index_triage_on_patient_id"
    t.index ["performed_by_user_id"], name: "index_triage_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_triage_on_programme_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "given_name", null: false
    t.string "family_name", null: false
    t.string "session_token"
    t.integer "fallback_role", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "vaccination_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivery_site"
    t.integer "outcome", null: false
    t.bigint "batch_id"
    t.integer "delivery_method"
    t.bigint "performed_by_user_id"
    t.text "notes"
    t.integer "dose_sequence"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "performed_at", null: false
    t.string "performed_by_given_name"
    t.string "performed_by_family_name"
    t.jsonb "pending_changes", default: {}, null: false
    t.bigint "programme_id", null: false
    t.string "location_name"
    t.datetime "discarded_at"
    t.datetime "confirmation_sent_at"
    t.bigint "patient_id"
    t.bigint "session_id"
    t.string "performed_ods_code"
    t.bigint "vaccine_id"
    t.boolean "full_dose"
    t.datetime "nhs_immunisations_api_synced_at"
    t.string "nhs_immunisations_api_id"
    t.string "nhs_immunisations_api_etag"
    t.integer "protocol"
    t.datetime "nhs_immunisations_api_sync_pending_at"
    t.index ["batch_id"], name: "index_vaccination_records_on_batch_id"
    t.index ["discarded_at"], name: "index_vaccination_records_on_discarded_at"
    t.index ["nhs_immunisations_api_id"], name: "index_vaccination_records_on_nhs_immunisations_api_id", unique: true
    t.index ["patient_id"], name: "index_vaccination_records_on_patient_id"
    t.index ["performed_by_user_id"], name: "index_vaccination_records_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_vaccination_records_on_programme_id"
    t.index ["session_id"], name: "index_vaccination_records_on_session_id"
    t.index ["uuid"], name: "index_vaccination_records_on_uuid", unique: true
    t.index ["vaccine_id"], name: "index_vaccination_records_on_vaccine_id"
  end

  create_table "vaccines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "brand", null: false
    t.integer "method", null: false
    t.text "manufacturer", null: false
    t.decimal "dose_volume_ml", null: false
    t.string "snomed_product_code", null: false
    t.string "snomed_product_term", null: false
    t.text "nivs_name", null: false
    t.boolean "discontinued", default: false, null: false
    t.bigint "programme_id", null: false
    t.integer "side_effects", default: [], null: false, array: true
    t.index ["manufacturer", "brand"], name: "index_vaccines_on_manufacturer_and_brand", unique: true
    t.index ["nivs_name"], name: "index_vaccines_on_nivs_name", unique: true
    t.index ["programme_id"], name: "index_vaccines_on_programme_id"
    t.index ["snomed_product_code"], name: "index_vaccines_on_snomed_product_code", unique: true
    t.index ["snomed_product_term"], name: "index_vaccines_on_snomed_product_term", unique: true
  end

  add_foreign_key "access_log_entries", "patients"
  add_foreign_key "access_log_entries", "users"
  add_foreign_key "batches", "organisations"
  add_foreign_key "batches", "vaccines"
  add_foreign_key "batches_immunisation_imports", "batches"
  add_foreign_key "batches_immunisation_imports", "immunisation_imports"
  add_foreign_key "class_imports", "organisations"
  add_foreign_key "class_imports", "sessions"
  add_foreign_key "class_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "class_imports_parent_relationships", "class_imports"
  add_foreign_key "class_imports_parent_relationships", "parent_relationships"
  add_foreign_key "class_imports_parents", "class_imports"
  add_foreign_key "class_imports_parents", "parents"
  add_foreign_key "class_imports_patients", "class_imports"
  add_foreign_key "class_imports_patients", "patients"
  add_foreign_key "cohort_imports", "organisations"
  add_foreign_key "cohort_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "cohort_imports_parent_relationships", "cohort_imports"
  add_foreign_key "cohort_imports_parent_relationships", "parent_relationships"
  add_foreign_key "cohort_imports_parents", "cohort_imports"
  add_foreign_key "cohort_imports_parents", "parents"
  add_foreign_key "cohort_imports_patients", "cohort_imports"
  add_foreign_key "cohort_imports_patients", "patients"
  add_foreign_key "consent_form_programmes", "consent_forms"
  add_foreign_key "consent_form_programmes", "programmes"
  add_foreign_key "consent_forms", "consents"
  add_foreign_key "consent_forms", "locations"
  add_foreign_key "consent_forms", "locations", column: "school_id"
  add_foreign_key "consent_forms", "organisations"
  add_foreign_key "consent_notification_programmes", "consent_notifications"
  add_foreign_key "consent_notification_programmes", "programmes"
  add_foreign_key "consent_notifications", "patients"
  add_foreign_key "consent_notifications", "sessions"
  add_foreign_key "consent_notifications", "users", column: "sent_by_user_id"
  add_foreign_key "consents", "organisations"
  add_foreign_key "consents", "parents"
  add_foreign_key "consents", "patients"
  add_foreign_key "consents", "programmes"
  add_foreign_key "consents", "users", column: "recorded_by_user_id"
  add_foreign_key "gillick_assessments", "patient_sessions"
  add_foreign_key "gillick_assessments", "programmes"
  add_foreign_key "gillick_assessments", "users", column: "performed_by_user_id"
  add_foreign_key "health_questions", "health_questions", column: "follow_up_question_id"
  add_foreign_key "health_questions", "health_questions", column: "next_question_id"
  add_foreign_key "health_questions", "vaccines"
  add_foreign_key "identity_checks", "vaccination_records", on_delete: :cascade
  add_foreign_key "immunisation_imports", "organisations"
  add_foreign_key "immunisation_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "immunisation_imports_patient_sessions", "immunisation_imports"
  add_foreign_key "immunisation_imports_patient_sessions", "patient_sessions"
  add_foreign_key "immunisation_imports_patients", "immunisation_imports"
  add_foreign_key "immunisation_imports_patients", "patients"
  add_foreign_key "immunisation_imports_sessions", "immunisation_imports"
  add_foreign_key "immunisation_imports_sessions", "sessions"
  add_foreign_key "immunisation_imports_vaccination_records", "immunisation_imports"
  add_foreign_key "immunisation_imports_vaccination_records", "vaccination_records"
  add_foreign_key "location_programme_year_groups", "locations", on_delete: :cascade
  add_foreign_key "location_programme_year_groups", "programmes", on_delete: :cascade
  add_foreign_key "locations", "teams"
  add_foreign_key "notes", "patients"
  add_foreign_key "notes", "sessions"
  add_foreign_key "notes", "users", column: "created_by_user_id"
  add_foreign_key "notify_log_entries", "consent_forms"
  add_foreign_key "notify_log_entries", "parents", on_delete: :nullify
  add_foreign_key "notify_log_entries", "patients"
  add_foreign_key "notify_log_entries", "users", column: "sent_by_user_id"
  add_foreign_key "organisation_programmes", "organisations"
  add_foreign_key "organisation_programmes", "programmes"
  add_foreign_key "parent_relationships", "parents"
  add_foreign_key "parent_relationships", "patients"
  add_foreign_key "patient_consent_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_consent_statuses", "programmes"
  add_foreign_key "patient_session_registration_statuses", "patient_sessions", on_delete: :cascade
  add_foreign_key "patient_session_session_statuses", "patient_sessions", on_delete: :cascade
  add_foreign_key "patient_session_session_statuses", "programmes"
  add_foreign_key "patient_sessions", "patients"
  add_foreign_key "patient_sessions", "sessions"
  add_foreign_key "patient_specific_directions", "patients"
  add_foreign_key "patient_specific_directions", "programmes"
  add_foreign_key "patient_specific_directions", "users", column: "created_by_user_id"
  add_foreign_key "patient_specific_directions", "vaccines"
  add_foreign_key "patient_triage_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_triage_statuses", "programmes"
  add_foreign_key "patient_vaccination_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_vaccination_statuses", "programmes"
  add_foreign_key "patients", "locations", column: "gp_practice_id"
  add_foreign_key "patients", "locations", column: "school_id"
  add_foreign_key "pre_screenings", "patient_sessions"
  add_foreign_key "pre_screenings", "programmes"
  add_foreign_key "pre_screenings", "users", column: "performed_by_user_id"
  add_foreign_key "school_move_log_entries", "locations", column: "school_id"
  add_foreign_key "school_move_log_entries", "patients"
  add_foreign_key "school_move_log_entries", "users"
  add_foreign_key "school_moves", "locations", column: "school_id"
  add_foreign_key "school_moves", "organisations"
  add_foreign_key "school_moves", "patients"
  add_foreign_key "session_attendances", "patient_sessions"
  add_foreign_key "session_attendances", "session_dates"
  add_foreign_key "session_dates", "sessions"
  add_foreign_key "session_notifications", "patients"
  add_foreign_key "session_notifications", "sessions"
  add_foreign_key "session_notifications", "users", column: "sent_by_user_id"
  add_foreign_key "session_programmes", "programmes"
  add_foreign_key "session_programmes", "sessions"
  add_foreign_key "sessions", "organisations"
  add_foreign_key "teams", "organisations"
  add_foreign_key "triage", "organisations"
  add_foreign_key "triage", "patients"
  add_foreign_key "triage", "programmes"
  add_foreign_key "triage", "users", column: "performed_by_user_id"
  add_foreign_key "vaccination_records", "batches"
  add_foreign_key "vaccination_records", "patients"
  add_foreign_key "vaccination_records", "programmes"
  add_foreign_key "vaccination_records", "sessions"
  add_foreign_key "vaccination_records", "users", column: "performed_by_user_id"
  add_foreign_key "vaccination_records", "vaccines"
  add_foreign_key "vaccines", "programmes"
end
