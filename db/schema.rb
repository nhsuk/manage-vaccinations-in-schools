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

ActiveRecord::Schema[8.1].define(version: 2025_11_06_142201) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "access_log_entries", force: :cascade do |t|
    t.integer "action", null: false
    t.integer "controller", null: false
    t.datetime "created_at", null: false
    t.bigint "patient_id", null: false
    t.jsonb "request_details"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["patient_id"], name: "index_access_log_entries_on_patient_id"
    t.index ["user_id"], name: "index_access_log_entries_on_user_id"
  end

  create_table "active_record_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_active_record_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_active_record_sessions_on_updated_at"
  end

  create_table "archive_reasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.string "other_details", default: "", null: false
    t.bigint "patient_id", null: false
    t.bigint "team_id", null: false
    t.integer "type", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_archive_reasons_on_created_by_user_id"
    t.index ["patient_id", "team_id"], name: "index_archive_reasons_on_patient_id_and_team_id", unique: true
    t.index ["patient_id"], name: "index_archive_reasons_on_patient_id"
    t.index ["team_id", "patient_id"], name: "index_archive_reasons_on_team_id_and_patient_id", unique: true
    t.index ["team_id"], name: "index_archive_reasons_on_team_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.boolean "attending", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "location_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_attendance_records_on_location_id"
    t.index ["patient_id", "location_id", "date"], name: "idx_on_patient_id_location_id_date_e5912f40c4", unique: true
    t.index ["patient_id"], name: "index_attendance_records_on_patient_id"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "batches", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.date "expiry"
    t.string "name", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.bigint "vaccine_id", null: false
    t.index ["team_id", "name", "expiry", "vaccine_id"], name: "index_batches_on_team_id_and_name_and_expiry_and_vaccine_id", unique: true
    t.index ["vaccine_id"], name: "index_batches_on_vaccine_id"
  end

  create_table "batches_immunisation_imports", id: false, force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.bigint "immunisation_import_id", null: false
    t.index ["immunisation_import_id", "batch_id"], name: "idx_on_immunisation_import_id_batch_id_d039b76103", unique: true
  end

  create_table "class_imports", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.integer "changed_record_count"
    t.datetime "created_at", null: false
    t.text "csv_data"
    t.text "csv_filename"
    t.datetime "csv_removed_at"
    t.integer "exact_duplicate_record_count"
    t.bigint "location_id", null: false
    t.integer "new_record_count"
    t.datetime "processed_at"
    t.integer "rows_count"
    t.jsonb "serialized_errors"
    t.integer "status", default: 0, null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_user_id", null: false
    t.integer "year_groups", default: [], null: false, array: true
    t.index ["location_id"], name: "index_class_imports_on_location_id"
    t.index ["team_id"], name: "index_class_imports_on_team_id"
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
    t.integer "academic_year", null: false
    t.integer "changed_record_count"
    t.datetime "created_at", null: false
    t.text "csv_data"
    t.text "csv_filename"
    t.datetime "csv_removed_at"
    t.integer "exact_duplicate_record_count"
    t.integer "new_record_count"
    t.datetime "processed_at"
    t.integer "rows_count"
    t.jsonb "serialized_errors"
    t.integer "status", default: 0, null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_user_id", null: false
    t.index ["team_id"], name: "index_cohort_imports_on_team_id"
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
    t.bigint "consent_form_id", null: false
    t.text "notes", default: "", null: false
    t.bigint "programme_id", null: false
    t.integer "reason_for_refusal"
    t.integer "response"
    t.integer "vaccine_methods", default: [], null: false, array: true
    t.boolean "without_gelatine"
    t.index ["consent_form_id"], name: "index_consent_form_programmes_on_consent_form_id"
    t.index ["programme_id", "consent_form_id"], name: "idx_on_programme_id_consent_form_id_2113cb7f37", unique: true
  end

  create_table "consent_forms", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_postcode"
    t.string "address_town"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.integer "education_setting"
    t.text "family_name"
    t.text "given_name"
    t.jsonb "health_answers", default: [], null: false
    t.bigint "location_id", null: false
    t.string "nhs_number"
    t.text "notes", default: "", null: false
    t.string "parent_contact_method_other_details"
    t.string "parent_contact_method_type"
    t.string "parent_email"
    t.string "parent_full_name"
    t.string "parent_phone"
    t.boolean "parent_phone_receive_updates", default: false, null: false
    t.string "parent_relationship_other_name"
    t.string "parent_relationship_type"
    t.string "preferred_family_name"
    t.string "preferred_given_name"
    t.datetime "recorded_at"
    t.boolean "school_confirmed"
    t.bigint "school_id"
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "use_preferred_name"
    t.index ["academic_year"], name: "index_consent_forms_on_academic_year"
    t.index ["location_id"], name: "index_consent_forms_on_location_id"
    t.index ["nhs_number"], name: "index_consent_forms_on_nhs_number"
    t.index ["school_id"], name: "index_consent_forms_on_school_id"
    t.index ["team_id"], name: "index_consent_forms_on_team_id"
  end

  create_table "consent_notification_programmes", force: :cascade do |t|
    t.bigint "consent_notification_id", null: false
    t.bigint "programme_id", null: false
    t.index ["consent_notification_id"], name: "idx_on_consent_notification_id_bde310472f"
    t.index ["programme_id", "consent_notification_id"], name: "idx_on_programme_id_consent_notification_id_e185bde5f5", unique: true
  end

  create_table "consent_notifications", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.datetime "sent_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "sent_by_user_id"
    t.bigint "session_id", null: false
    t.integer "type", null: false
    t.index ["patient_id"], name: "index_consent_notifications_on_patient_id"
    t.index ["sent_by_user_id"], name: "index_consent_notifications_on_sent_by_user_id"
    t.index ["session_id"], name: "index_consent_notifications_on_session_id"
  end

  create_table "consents", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.bigint "consent_form_id"
    t.datetime "created_at", null: false
    t.jsonb "health_answers", default: [], null: false
    t.datetime "invalidated_at"
    t.text "notes", default: "", null: false
    t.boolean "notify_parent_on_refusal"
    t.boolean "notify_parents_on_vaccination"
    t.bigint "parent_id"
    t.datetime "patient_already_vaccinated_notification_sent_at"
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "reason_for_refusal"
    t.bigint "recorded_by_user_id"
    t.integer "response", null: false
    t.integer "route", null: false
    t.datetime "submitted_at", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "vaccine_methods", default: [], null: false, array: true
    t.datetime "withdrawn_at"
    t.boolean "without_gelatine"
    t.index ["academic_year"], name: "index_consents_on_academic_year"
    t.index ["consent_form_id"], name: "index_consents_on_consent_form_id"
    t.index ["parent_id"], name: "index_consents_on_parent_id"
    t.index ["patient_id"], name: "index_consents_on_patient_id"
    t.index ["programme_id"], name: "index_consents_on_programme_id"
    t.index ["recorded_by_user_id"], name: "index_consents_on_recorded_by_user_id"
    t.index ["team_id"], name: "index_consents_on_team_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "gillick_assessments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "knows_consequences", null: false
    t.boolean "knows_delivery", null: false
    t.boolean "knows_disease", null: false
    t.boolean "knows_side_effects", null: false
    t.boolean "knows_vaccination", null: false
    t.text "notes", default: "", null: false
    t.bigint "patient_id", null: false
    t.bigint "performed_by_user_id", null: false
    t.bigint "programme_id", null: false
    t.bigint "session_date_id", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_gillick_assessments_on_patient_id"
    t.index ["performed_by_user_id"], name: "index_gillick_assessments_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_gillick_assessments_on_programme_id"
    t.index ["session_date_id"], name: "index_gillick_assessments_on_session_date_id"
  end

  create_table "health_questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "follow_up_question_id"
    t.string "give_details_hint"
    t.string "hint"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "next_question_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "vaccine_id", null: false
    t.boolean "would_require_triage", default: true, null: false
    t.index ["follow_up_question_id"], name: "index_health_questions_on_follow_up_question_id"
    t.index ["next_question_id"], name: "index_health_questions_on_next_question_id"
    t.index ["vaccine_id"], name: "index_health_questions_on_vaccine_id"
  end

  create_table "identity_checks", force: :cascade do |t|
    t.string "confirmed_by_other_name", default: "", null: false
    t.string "confirmed_by_other_relationship", default: "", null: false
    t.boolean "confirmed_by_patient", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "vaccination_record_id", null: false
    t.index ["vaccination_record_id"], name: "index_identity_checks_on_vaccination_record_id"
  end

  create_table "immunisation_imports", force: :cascade do |t|
    t.integer "changed_record_count"
    t.datetime "created_at", null: false
    t.text "csv_data"
    t.text "csv_filename", null: false
    t.datetime "csv_removed_at"
    t.integer "exact_duplicate_record_count"
    t.integer "new_record_count"
    t.datetime "processed_at"
    t.integer "rows_count"
    t.jsonb "serialized_errors"
    t.integer "status", default: 0, null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_user_id", null: false
    t.index ["team_id"], name: "index_immunisation_imports_on_team_id"
    t.index ["uploaded_by_user_id"], name: "index_immunisation_imports_on_uploaded_by_user_id"
  end

  create_table "immunisation_imports_patient_locations", id: false, force: :cascade do |t|
    t.bigint "immunisation_import_id", null: false
    t.bigint "patient_location_id", null: false
    t.index ["immunisation_import_id", "patient_location_id"], name: "idx_on_immunisation_import_id_patient_location_id_97ddfb7192", unique: true
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

  create_table "important_notices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "dismissed_at"
    t.bigint "dismissed_by_user_id"
    t.bigint "patient_id", null: false
    t.datetime "recorded_at", null: false
    t.bigint "team_id", null: false
    t.integer "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "vaccination_record_id"
    t.index ["dismissed_by_user_id"], name: "index_important_notices_on_dismissed_by_user_id"
    t.index ["patient_id", "type", "recorded_at", "team_id"], name: "index_notices_on_patient_and_type_and_recorded_at_and_team", unique: true
    t.index ["patient_id"], name: "index_important_notices_on_patient_id"
    t.index ["team_id"], name: "index_important_notices_on_team_id"
    t.index ["vaccination_record_id"], name: "index_important_notices_on_vaccination_record_id"
  end

  create_table "local_authorities", id: false, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.integer "gias_code"
    t.string "gov_uk_slug"
    t.string "gss_code"
    t.string "mhclg_code", null: false
    t.string "nation", null: false
    t.string "official_name", null: false
    t.string "region"
    t.string "short_name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_local_authorities_on_created_at"
    t.index ["gias_code"], name: "index_local_authorities_on_gias_code", unique: true
    t.index ["gss_code"], name: "index_local_authorities_on_gss_code", unique: true
    t.index ["mhclg_code"], name: "index_local_authorities_on_mhclg_code", unique: true
    t.index ["nation", "short_name"], name: "index_local_authorities_on_nation_and_short_name"
    t.index ["short_name"], name: "index_local_authorities_on_short_name"
  end

  create_table "local_authority_postcodes", id: false, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gss_code", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["gss_code"], name: "index_local_authority_postcodes_on_gss_code"
    t.index ["value"], name: "index_local_authority_postcodes_on_value", unique: true
  end

  create_table "location_programme_year_groups", force: :cascade do |t|
    t.bigint "location_year_group_id", null: false
    t.bigint "programme_id", null: false
    t.index ["location_year_group_id", "programme_id"], name: "idx_on_location_year_group_id_programme_id_405f51181e", unique: true
    t.index ["location_year_group_id"], name: "index_location_programme_year_groups_on_location_year_group_id"
    t.index ["programme_id"], name: "index_location_programme_year_groups_on_programme_id"
  end

  create_table "location_year_groups", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
    t.integer "source", null: false
    t.datetime "updated_at", null: false
    t.integer "value", null: false
    t.index ["location_id", "academic_year", "value"], name: "idx_on_location_id_academic_year_value_d553b03752", unique: true
    t.index ["location_id"], name: "index_location_year_groups_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.text "address_line_1"
    t.text "address_line_2"
    t.text "address_postcode"
    t.text "address_town"
    t.datetime "created_at", null: false
    t.integer "gias_establishment_number"
    t.integer "gias_local_authority_code"
    t.integer "gias_year_groups", default: [], null: false, array: true
    t.text "name", null: false
    t.string "ods_code"
    t.string "site"
    t.integer "status", default: 0, null: false
    t.bigint "subteam_id"
    t.string "systm_one_code"
    t.integer "type", null: false
    t.datetime "updated_at", null: false
    t.text "url"
    t.string "urn"
    t.index ["ods_code"], name: "index_locations_on_ods_code", unique: true
    t.index ["subteam_id"], name: "index_locations_on_subteam_id"
    t.index ["systm_one_code"], name: "index_locations_on_systm_one_code", unique: true
    t.index ["urn", "site"], name: "index_locations_on_urn_and_site", unique: true
    t.index ["urn"], name: "index_locations_on_urn", unique: true, where: "(site IS NULL)"
  end

  create_table "notes", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_notes_on_created_by_user_id"
    t.index ["patient_id"], name: "index_notes_on_patient_id"
    t.index ["session_id"], name: "index_notes_on_session_id"
  end

  create_table "notify_log_entries", force: :cascade do |t|
    t.bigint "consent_form_id"
    t.datetime "created_at", null: false
    t.uuid "delivery_id"
    t.integer "delivery_status", default: 0, null: false
    t.bigint "parent_id"
    t.bigint "patient_id"
    t.integer "programme_ids", default: [], null: false, array: true
    t.string "recipient", null: false
    t.bigint "sent_by_user_id"
    t.uuid "template_id", null: false
    t.integer "type", null: false
    t.index ["consent_form_id"], name: "index_notify_log_entries_on_consent_form_id"
    t.index ["delivery_id"], name: "index_notify_log_entries_on_delivery_id"
    t.index ["parent_id"], name: "index_notify_log_entries_on_parent_id"
    t.index ["patient_id"], name: "index_notify_log_entries_on_patient_id"
    t.index ["sent_by_user_id"], name: "index_notify_log_entries_on_sent_by_user_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ods_code", null: false
    t.datetime "updated_at", null: false
    t.index ["ods_code"], name: "index_organisations_on_ods_code", unique: true
  end

  create_table "parent_relationships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "other_name"
    t.bigint "parent_id", null: false
    t.bigint "patient_id", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "patient_id"], name: "index_parent_relationships_on_parent_id_and_patient_id", unique: true
    t.index ["patient_id"], name: "index_parent_relationships_on_patient_id"
  end

  create_table "parents", force: :cascade do |t|
    t.text "contact_method_other_details"
    t.string "contact_method_type"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "full_name"
    t.string "phone"
    t.boolean "phone_receive_updates", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_parents_on_email"
  end

  create_table "patient_changesets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.bigint "import_id", null: false
    t.string "import_type", null: false
    t.boolean "matched_on_nhs_number"
    t.bigint "patient_id"
    t.string "pds_nhs_number"
    t.jsonb "pending_changes", default: {}, null: false
    t.integer "record_type", default: 1, null: false
    t.integer "row_number"
    t.bigint "school_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "uploaded_nhs_number"
    t.index ["import_type", "import_id"], name: "index_patient_changesets_on_import"
    t.index ["patient_id"], name: "index_patient_changesets_on_patient_id"
    t.index ["status"], name: "index_patient_changesets_on_status"
  end

  create_table "patient_consent_statuses", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "vaccine_methods", default: [], null: false, array: true
    t.boolean "without_gelatine"
    t.index ["academic_year", "patient_id"], name: "index_patient_consent_statuses_on_academic_year_and_patient_id"
    t.index ["patient_id", "programme_id", "academic_year"], name: "idx_on_patient_id_programme_id_academic_year_1d3170e398", unique: true
    t.index ["status"], name: "index_patient_consent_statuses_on_status"
  end

  create_table "patient_locations", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
    t.bigint "patient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "academic_year", "patient_id"], name: "idx_on_location_id_academic_year_patient_id_3237b32fa0", unique: true
    t.index ["location_id", "academic_year"], name: "index_patient_locations_on_location_id_and_academic_year"
    t.index ["location_id"], name: "index_patient_locations_on_location_id"
    t.index ["patient_id", "location_id", "academic_year"], name: "idx_on_patient_id_location_id_academic_year_08a1dc4afe", unique: true
  end

  create_table "patient_registration_statuses", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "session_id", null: false
    t.integer "status", default: 0, null: false
    t.index ["patient_id", "session_id"], name: "idx_on_patient_id_session_id_2ff02d8889", unique: true
    t.index ["patient_id"], name: "index_patient_registration_statuses_on_patient_id"
    t.index ["session_id"], name: "index_patient_registration_statuses_on_session_id"
    t.index ["status"], name: "index_patient_registration_statuses_on_status"
  end

  create_table "patient_specific_directions", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id", null: false
    t.integer "delivery_site", null: false
    t.datetime "invalidated_at"
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vaccine_id", null: false
    t.integer "vaccine_method", null: false
    t.index ["academic_year"], name: "index_patient_specific_directions_on_academic_year"
    t.index ["created_by_user_id"], name: "index_patient_specific_directions_on_created_by_user_id"
    t.index ["patient_id"], name: "index_patient_specific_directions_on_patient_id"
    t.index ["programme_id"], name: "index_patient_specific_directions_on_programme_id"
    t.index ["team_id"], name: "index_patient_specific_directions_on_team_id"
    t.index ["vaccine_id"], name: "index_patient_specific_directions_on_vaccine_id"
  end

  create_table "patient_teams", primary_key: ["team_id", "patient_id"], force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.integer "sources", null: false, array: true
    t.bigint "team_id", null: false
    t.index ["patient_id", "team_id"], name: "index_patient_teams_on_patient_id_and_team_id"
    t.index ["patient_id"], name: "index_patient_teams_on_patient_id"
    t.index ["sources"], name: "index_patient_teams_on_sources", using: :gin
    t.index ["team_id"], name: "index_patient_teams_on_team_id"
  end

  create_table "patient_triage_statuses", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "vaccine_method"
    t.boolean "without_gelatine"
    t.index ["academic_year", "patient_id"], name: "index_patient_triage_statuses_on_academic_year_and_patient_id"
    t.index ["patient_id", "programme_id", "academic_year"], name: "idx_on_patient_id_programme_id_academic_year_6cf32349df", unique: true
    t.index ["status"], name: "index_patient_triage_statuses_on_status"
  end

  create_table "patient_vaccination_statuses", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.integer "dose_sequence"
    t.date "latest_date"
    t.bigint "latest_location_id"
    t.integer "latest_session_status"
    t.bigint "patient_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", default: 0, null: false
    t.index ["academic_year", "patient_id"], name: "idx_on_academic_year_patient_id_9c400fc863"
    t.index ["latest_location_id"], name: "index_patient_vaccination_statuses_on_latest_location_id"
    t.index ["patient_id", "programme_id", "academic_year"], name: "idx_on_patient_id_programme_id_academic_year_fc0b47b743", unique: true
    t.index ["status"], name: "index_patient_vaccination_statuses_on_status"
  end

  create_table "patients", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_postcode"
    t.string "address_town"
    t.integer "birth_academic_year", null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.date "date_of_death"
    t.datetime "date_of_death_recorded_at"
    t.string "family_name", null: false
    t.integer "gender_code", default: 0, null: false
    t.string "given_name", null: false
    t.bigint "gp_practice_id"
    t.boolean "home_educated"
    t.datetime "invalidated_at"
    t.string "nhs_number"
    t.jsonb "pending_changes", default: {}, null: false
    t.string "preferred_family_name"
    t.string "preferred_given_name"
    t.string "registration"
    t.integer "registration_academic_year"
    t.datetime "restricted_at"
    t.bigint "school_id"
    t.datetime "updated_at", null: false
    t.datetime "updated_from_pds_at"
    t.index ["family_name", "given_name"], name: "index_patients_on_names_family_first"
    t.index ["family_name"], name: "index_patients_on_family_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["given_name", "family_name"], name: "index_patients_on_names_given_first"
    t.index ["given_name"], name: "index_patients_on_given_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["gp_practice_id"], name: "index_patients_on_gp_practice_id"
    t.index ["id"], name: "index_patients_on_pending_changes_not_empty", where: "(pending_changes <> '{}'::jsonb)"
    t.index ["nhs_number"], name: "index_patients_on_nhs_number", unique: true
    t.index ["school_id"], name: "index_patients_on_school_id"
  end

  create_table "pds_search_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "import_id"
    t.string "import_type"
    t.string "nhs_number"
    t.bigint "patient_id", null: false
    t.integer "result", null: false
    t.integer "step", null: false
    t.datetime "updated_at", null: false
    t.index ["import_type", "import_id"], name: "index_pds_search_results_on_import"
    t.index ["patient_id"], name: "index_pds_search_results_on_patient_id"
  end

  create_table "pre_screenings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes", default: "", null: false
    t.bigint "patient_id", null: false
    t.bigint "performed_by_user_id", null: false
    t.bigint "programme_id", null: false
    t.bigint "session_date_id", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_pre_screenings_on_patient_id"
    t.index ["performed_by_user_id"], name: "index_pre_screenings_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_pre_screenings_on_programme_id"
    t.index ["session_date_id"], name: "index_pre_screenings_on_session_date_id"
  end

  create_table "programmes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_programmes_on_type", unique: true
  end

  create_table "reporting_api_one_time_tokens", primary_key: "token", id: :string, force: :cascade do |t|
    t.jsonb "cis2_info", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_reporting_api_one_time_tokens_on_created_at"
    t.index ["token"], name: "index_reporting_api_one_time_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_reporting_api_one_time_tokens_on_user_id", unique: true
  end

  create_table "school_move_log_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "home_educated"
    t.bigint "patient_id", null: false
    t.bigint "school_id"
    t.bigint "user_id"
    t.index ["patient_id"], name: "index_school_move_log_entries_on_patient_id"
    t.index ["school_id"], name: "index_school_move_log_entries_on_school_id"
    t.index ["user_id"], name: "index_school_move_log_entries_on_user_id"
  end

  create_table "school_moves", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.datetime "created_at", null: false
    t.boolean "home_educated"
    t.bigint "patient_id", null: false
    t.bigint "school_id"
    t.integer "source", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.index ["patient_id", "school_id"], name: "index_school_moves_on_patient_id_and_school_id"
    t.index ["patient_id"], name: "index_school_moves_on_patient_id", unique: true
    t.index ["school_id"], name: "index_school_moves_on_school_id"
    t.index ["team_id"], name: "index_school_moves_on_team_id"
  end

  create_table "session_dates", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.date "value", null: false
    t.index ["session_id", "value"], name: "index_session_dates_on_session_id_and_value", unique: true
  end

  create_table "session_notifications", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.datetime "sent_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "sent_by_user_id"
    t.date "session_date", null: false
    t.bigint "session_id", null: false
    t.integer "type", null: false
    t.index ["patient_id", "session_id", "session_date"], name: "idx_on_patient_id_session_id_session_date_f7f30a3aa3"
    t.index ["sent_by_user_id"], name: "index_session_notifications_on_sent_by_user_id"
    t.index ["session_id"], name: "index_session_notifications_on_session_id"
  end

  create_table "session_programmes", force: :cascade do |t|
    t.bigint "programme_id", null: false
    t.bigint "session_id", null: false
    t.index ["programme_id"], name: "index_session_programmes_on_programme_id"
    t.index ["session_id", "programme_id"], name: "index_session_programmes_on_session_id_and_programme_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.datetime "created_at", null: false
    t.integer "days_before_consent_reminders"
    t.bigint "location_id", null: false
    t.boolean "national_protocol_enabled", default: false, null: false
    t.boolean "psd_enabled", default: false, null: false
    t.boolean "requires_registration", default: true, null: false
    t.date "send_consent_requests_at"
    t.date "send_invitations_at"
    t.string "slug", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year", "location_id", "team_id"], name: "index_sessions_on_academic_year_and_location_id_and_team_id"
    t.index ["location_id", "academic_year", "team_id"], name: "index_sessions_on_location_id_and_academic_year_and_team_id"
    t.index ["location_id"], name: "index_sessions_on_location_id"
    t.index ["team_id", "academic_year"], name: "index_sessions_on_team_id_and_academic_year"
    t.index ["team_id", "location_id"], name: "index_sessions_on_team_id_and_location_id"
  end

  create_table "subteams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.string "phone_instructions"
    t.uuid "reply_to_id"
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "name"], name: "index_subteams_on_team_id_and_name", unique: true
  end

  create_table "team_programmes", force: :cascade do |t|
    t.bigint "programme_id", null: false
    t.bigint "team_id", null: false
    t.index ["programme_id"], name: "index_team_programmes_on_programme_id"
    t.index ["team_id", "programme_id"], name: "index_team_programmes_on_team_id_and_programme_id", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.string "careplus_venue_code", null: false
    t.datetime "created_at", null: false
    t.integer "days_before_consent_reminders", default: 7, null: false
    t.integer "days_before_consent_requests", default: 21, null: false
    t.integer "days_before_invitations", default: 21, null: false
    t.string "email"
    t.text "name", null: false
    t.bigint "organisation_id", null: false
    t.string "phone"
    t.string "phone_instructions"
    t.string "privacy_notice_url", null: false
    t.string "privacy_policy_url", null: false
    t.uuid "reply_to_id"
    t.datetime "updated_at", null: false
    t.string "workgroup", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["organisation_id"], name: "index_teams_on_organisation_id"
    t.index ["workgroup"], name: "index_teams_on_workgroup", unique: true
  end

  create_table "teams_users", id: false, force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.index ["team_id", "user_id"], name: "index_teams_users_on_team_id_and_user_id"
    t.index ["user_id", "team_id"], name: "index_teams_users_on_user_id_and_team_id"
  end

  create_table "triages", force: :cascade do |t|
    t.integer "academic_year", null: false
    t.datetime "created_at", null: false
    t.date "delay_vaccination_until"
    t.datetime "invalidated_at"
    t.text "notes", default: "", null: false
    t.bigint "patient_id", null: false
    t.bigint "performed_by_user_id", null: false
    t.bigint "programme_id", null: false
    t.integer "status", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "vaccine_method"
    t.boolean "without_gelatine"
    t.index ["academic_year"], name: "index_triages_on_academic_year"
    t.index ["patient_id"], name: "index_triages_on_patient_id"
    t.index ["performed_by_user_id"], name: "index_triages_on_performed_by_user_id"
    t.index ["programme_id"], name: "index_triages_on_programme_id"
    t.index ["team_id"], name: "index_triages_on_team_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.integer "fallback_role"
    t.string "family_name", null: false
    t.string "given_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "provider"
    t.datetime "remember_created_at"
    t.string "reporting_api_session_token"
    t.string "session_token"
    t.boolean "show_in_suppliers", default: false, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reporting_api_session_token"], name: "index_users_on_reporting_api_session_token", unique: true
  end

  create_table "vaccination_records", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at", null: false
    t.integer "delivery_method"
    t.integer "delivery_site"
    t.datetime "discarded_at"
    t.integer "dose_sequence"
    t.boolean "full_dose"
    t.bigint "location_id"
    t.string "location_name"
    t.bigint "next_dose_delay_triage_id"
    t.string "nhs_immunisations_api_etag"
    t.string "nhs_immunisations_api_id"
    t.string "nhs_immunisations_api_identifier_system"
    t.string "nhs_immunisations_api_identifier_value"
    t.boolean "nhs_immunisations_api_primary_source"
    t.datetime "nhs_immunisations_api_sync_pending_at"
    t.datetime "nhs_immunisations_api_synced_at"
    t.text "notes"
    t.boolean "notify_parents"
    t.integer "outcome", null: false
    t.bigint "patient_id", null: false
    t.jsonb "pending_changes", default: {}, null: false
    t.datetime "performed_at", null: false
    t.string "performed_by_family_name"
    t.string "performed_by_given_name"
    t.bigint "performed_by_user_id"
    t.string "performed_ods_code"
    t.bigint "programme_id", null: false
    t.integer "protocol"
    t.bigint "session_id"
    t.integer "source", null: false
    t.bigint "supplied_by_user_id"
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "vaccine_id"
    t.index ["batch_id"], name: "index_vaccination_records_on_batch_id"
    t.index ["discarded_at"], name: "index_vaccination_records_on_discarded_at"
    t.index ["id"], name: "index_vaccination_records_on_pending_changes_not_empty", where: "(pending_changes <> '{}'::jsonb)"
    t.index ["location_id"], name: "index_vaccination_records_on_location_id"
    t.index ["next_dose_delay_triage_id"], name: "index_vaccination_records_on_next_dose_delay_triage_id"
    t.index ["nhs_immunisations_api_id"], name: "index_vaccination_records_on_nhs_immunisations_api_id", unique: true
    t.index ["patient_id", "programme_id", "outcome"], name: "idx_vr_fast_lookup", where: "(discarded_at IS NULL)"
    t.index ["patient_id", "session_id"], name: "index_vaccination_records_on_patient_id_and_session_id"
    t.index ["patient_id"], name: "index_vaccination_records_on_patient_id"
    t.index ["performed_by_user_id"], name: "index_vaccination_records_on_performed_by_user_id"
    t.index ["performed_ods_code", "patient_id"], name: "index_vaccination_records_on_performed_ods_code_and_patient_id", where: "(session_id IS NULL)"
    t.index ["programme_id"], name: "index_vaccination_records_on_programme_id"
    t.index ["session_id"], name: "index_vaccination_records_on_session_id"
    t.index ["supplied_by_user_id"], name: "index_vaccination_records_on_supplied_by_user_id"
    t.index ["uuid"], name: "index_vaccination_records_on_uuid", unique: true
    t.index ["vaccine_id"], name: "index_vaccination_records_on_vaccine_id"
    t.check_constraint "session_id IS NULL AND source <> 0 OR session_id IS NOT NULL AND source = 0", name: "source_check"
  end

  create_table "vaccines", force: :cascade do |t|
    t.text "brand", null: false
    t.boolean "contains_gelatine", null: false
    t.datetime "created_at", null: false
    t.boolean "discontinued", default: false, null: false
    t.decimal "dose_volume_ml", null: false
    t.text "manufacturer", null: false
    t.integer "method", null: false
    t.text "nivs_name", null: false
    t.bigint "programme_id", null: false
    t.integer "side_effects", default: [], null: false, array: true
    t.string "snomed_product_code", null: false
    t.string "snomed_product_term", null: false
    t.datetime "updated_at", null: false
    t.index ["manufacturer", "brand"], name: "index_vaccines_on_manufacturer_and_brand", unique: true
    t.index ["nivs_name"], name: "index_vaccines_on_nivs_name", unique: true
    t.index ["programme_id"], name: "index_vaccines_on_programme_id"
    t.index ["snomed_product_code"], name: "index_vaccines_on_snomed_product_code", unique: true
    t.index ["snomed_product_term"], name: "index_vaccines_on_snomed_product_term", unique: true
  end

  add_foreign_key "access_log_entries", "patients"
  add_foreign_key "access_log_entries", "users"
  add_foreign_key "archive_reasons", "patients"
  add_foreign_key "archive_reasons", "teams"
  add_foreign_key "archive_reasons", "users", column: "created_by_user_id"
  add_foreign_key "attendance_records", "locations"
  add_foreign_key "attendance_records", "patients"
  add_foreign_key "batches", "teams"
  add_foreign_key "batches", "vaccines"
  add_foreign_key "batches_immunisation_imports", "batches", on_delete: :cascade
  add_foreign_key "batches_immunisation_imports", "immunisation_imports", on_delete: :cascade
  add_foreign_key "class_imports", "locations"
  add_foreign_key "class_imports", "teams"
  add_foreign_key "class_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "class_imports_parent_relationships", "class_imports", on_delete: :cascade
  add_foreign_key "class_imports_parent_relationships", "parent_relationships", on_delete: :cascade
  add_foreign_key "class_imports_parents", "class_imports", on_delete: :cascade
  add_foreign_key "class_imports_parents", "parents", on_delete: :cascade
  add_foreign_key "class_imports_patients", "class_imports", on_delete: :cascade
  add_foreign_key "class_imports_patients", "patients", on_delete: :cascade
  add_foreign_key "cohort_imports", "teams"
  add_foreign_key "cohort_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "cohort_imports_parent_relationships", "cohort_imports", on_delete: :cascade
  add_foreign_key "cohort_imports_parent_relationships", "parent_relationships", on_delete: :cascade
  add_foreign_key "cohort_imports_parents", "cohort_imports", on_delete: :cascade
  add_foreign_key "cohort_imports_parents", "parents", on_delete: :cascade
  add_foreign_key "cohort_imports_patients", "cohort_imports", on_delete: :cascade
  add_foreign_key "cohort_imports_patients", "patients", on_delete: :cascade
  add_foreign_key "consent_form_programmes", "consent_forms", on_delete: :cascade
  add_foreign_key "consent_form_programmes", "programmes", on_delete: :cascade
  add_foreign_key "consent_forms", "locations"
  add_foreign_key "consent_forms", "locations", column: "school_id"
  add_foreign_key "consent_forms", "teams"
  add_foreign_key "consent_notification_programmes", "consent_notifications", on_delete: :cascade
  add_foreign_key "consent_notification_programmes", "programmes", on_delete: :cascade
  add_foreign_key "consent_notifications", "patients"
  add_foreign_key "consent_notifications", "sessions"
  add_foreign_key "consent_notifications", "users", column: "sent_by_user_id"
  add_foreign_key "consents", "consent_forms"
  add_foreign_key "consents", "parents"
  add_foreign_key "consents", "patients"
  add_foreign_key "consents", "programmes"
  add_foreign_key "consents", "teams"
  add_foreign_key "consents", "users", column: "recorded_by_user_id"
  add_foreign_key "gillick_assessments", "patients"
  add_foreign_key "gillick_assessments", "programmes"
  add_foreign_key "gillick_assessments", "session_dates"
  add_foreign_key "gillick_assessments", "users", column: "performed_by_user_id"
  add_foreign_key "health_questions", "health_questions", column: "follow_up_question_id"
  add_foreign_key "health_questions", "health_questions", column: "next_question_id"
  add_foreign_key "health_questions", "vaccines"
  add_foreign_key "identity_checks", "vaccination_records", on_delete: :cascade
  add_foreign_key "immunisation_imports", "teams"
  add_foreign_key "immunisation_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "immunisation_imports_patient_locations", "immunisation_imports", on_delete: :cascade
  add_foreign_key "immunisation_imports_patient_locations", "patient_locations", on_delete: :cascade
  add_foreign_key "immunisation_imports_patients", "immunisation_imports", on_delete: :cascade
  add_foreign_key "immunisation_imports_patients", "patients", on_delete: :cascade
  add_foreign_key "immunisation_imports_sessions", "immunisation_imports", on_delete: :cascade
  add_foreign_key "immunisation_imports_sessions", "sessions", on_delete: :cascade
  add_foreign_key "immunisation_imports_vaccination_records", "immunisation_imports", on_delete: :cascade
  add_foreign_key "immunisation_imports_vaccination_records", "vaccination_records", on_delete: :cascade
  add_foreign_key "important_notices", "patients"
  add_foreign_key "important_notices", "teams"
  add_foreign_key "important_notices", "users", column: "dismissed_by_user_id"
  add_foreign_key "important_notices", "vaccination_records"
  add_foreign_key "location_programme_year_groups", "location_year_groups", on_delete: :cascade
  add_foreign_key "location_programme_year_groups", "programmes", on_delete: :cascade
  add_foreign_key "location_year_groups", "locations", on_delete: :cascade
  add_foreign_key "locations", "subteams"
  add_foreign_key "notes", "patients"
  add_foreign_key "notes", "sessions"
  add_foreign_key "notes", "users", column: "created_by_user_id"
  add_foreign_key "notify_log_entries", "consent_forms"
  add_foreign_key "notify_log_entries", "parents", on_delete: :nullify
  add_foreign_key "notify_log_entries", "patients"
  add_foreign_key "notify_log_entries", "users", column: "sent_by_user_id"
  add_foreign_key "parent_relationships", "parents"
  add_foreign_key "parent_relationships", "patients"
  add_foreign_key "patient_changesets", "locations", column: "school_id"
  add_foreign_key "patient_changesets", "patients"
  add_foreign_key "patient_consent_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_consent_statuses", "programmes"
  add_foreign_key "patient_locations", "locations"
  add_foreign_key "patient_locations", "patients"
  add_foreign_key "patient_registration_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_registration_statuses", "sessions", on_delete: :cascade
  add_foreign_key "patient_specific_directions", "patients"
  add_foreign_key "patient_specific_directions", "programmes"
  add_foreign_key "patient_specific_directions", "teams"
  add_foreign_key "patient_specific_directions", "users", column: "created_by_user_id"
  add_foreign_key "patient_specific_directions", "vaccines"
  add_foreign_key "patient_teams", "patients", on_delete: :cascade
  add_foreign_key "patient_teams", "teams", on_delete: :cascade
  add_foreign_key "patient_triage_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_triage_statuses", "programmes"
  add_foreign_key "patient_vaccination_statuses", "locations", column: "latest_location_id"
  add_foreign_key "patient_vaccination_statuses", "patients", on_delete: :cascade
  add_foreign_key "patient_vaccination_statuses", "programmes"
  add_foreign_key "patients", "locations", column: "gp_practice_id"
  add_foreign_key "patients", "locations", column: "school_id"
  add_foreign_key "pds_search_results", "patients"
  add_foreign_key "pre_screenings", "patients"
  add_foreign_key "pre_screenings", "programmes"
  add_foreign_key "pre_screenings", "session_dates"
  add_foreign_key "pre_screenings", "users", column: "performed_by_user_id"
  add_foreign_key "reporting_api_one_time_tokens", "users"
  add_foreign_key "school_move_log_entries", "locations", column: "school_id"
  add_foreign_key "school_move_log_entries", "patients"
  add_foreign_key "school_move_log_entries", "users"
  add_foreign_key "school_moves", "locations", column: "school_id"
  add_foreign_key "school_moves", "patients"
  add_foreign_key "school_moves", "teams"
  add_foreign_key "session_dates", "sessions"
  add_foreign_key "session_notifications", "patients"
  add_foreign_key "session_notifications", "sessions"
  add_foreign_key "session_notifications", "users", column: "sent_by_user_id"
  add_foreign_key "session_programmes", "programmes", on_delete: :cascade
  add_foreign_key "session_programmes", "sessions", on_delete: :cascade
  add_foreign_key "sessions", "teams"
  add_foreign_key "subteams", "teams"
  add_foreign_key "team_programmes", "programmes", on_delete: :cascade
  add_foreign_key "team_programmes", "teams", on_delete: :cascade
  add_foreign_key "teams", "organisations"
  add_foreign_key "triages", "patients"
  add_foreign_key "triages", "programmes"
  add_foreign_key "triages", "teams"
  add_foreign_key "triages", "users", column: "performed_by_user_id"
  add_foreign_key "vaccination_records", "batches"
  add_foreign_key "vaccination_records", "patients"
  add_foreign_key "vaccination_records", "programmes"
  add_foreign_key "vaccination_records", "sessions"
  add_foreign_key "vaccination_records", "triages", column: "next_dose_delay_triage_id"
  add_foreign_key "vaccination_records", "users", column: "performed_by_user_id"
  add_foreign_key "vaccination_records", "users", column: "supplied_by_user_id"
  add_foreign_key "vaccination_records", "vaccines"
  add_foreign_key "vaccines", "programmes"

  create_view "reporting_api_patient_programme_statuses", materialized: true, sql_definition: <<-SQL
      WITH base_data AS (
           SELECT concat(p.id, '-', prog.id, '-', t.id, '-', s.academic_year) AS id,
              p.id AS patient_id,
                  CASE p.gender_code
                      WHEN 0 THEN 'not known'::text
                      WHEN 1 THEN 'male'::text
                      WHEN 2 THEN 'female'::text
                      WHEN 9 THEN 'not specified'::text
                      ELSE NULL::text
                  END AS patient_gender,
              prog.id AS programme_id,
              prog.type AS programme_type,
              s.academic_year,
              t.id AS team_id,
              t.name AS team_name,
              COALESCE(patient_school_org.id, patient_location_org.id) AS organisation_id,
              COALESCE(school_la.mhclg_code, ''::character varying) AS patient_school_local_authority_code,
              COALESCE(school_la.mhclg_code, ''::character varying) AS patient_local_authority_code,
              school.id AS patient_school_id,
                  CASE
                      WHEN (school.name IS NOT NULL) THEN school.name
                      WHEN (p.home_educated = true) THEN 'Home educated'::text
                      ELSE 'Unknown'::text
                  END AS patient_school_name,
              pl.location_id AS session_location_id,
                  CASE
                      WHEN (p.birth_academic_year IS NOT NULL) THEN ((s.academic_year - p.birth_academic_year) - 5)
                      ELSE NULL::integer
                  END AS patient_year_group,
                  CASE
                      WHEN (vr_any.patient_id IS NOT NULL) THEN true
                      ELSE false
                  END AS has_any_vaccination,
                  CASE
                      WHEN (vr_sais_current.patient_id IS NOT NULL) THEN true
                      ELSE false
                  END AS vaccinated_by_sais_current_year,
                  CASE
                      WHEN ((vr_elsewhere_declared.patient_id IS NOT NULL) AND (vr_elsewhere_recorded.patient_id IS NULL)) THEN true
                      ELSE false
                  END AS vaccinated_elsewhere_declared_current_year,
                  CASE
                      WHEN (vr_elsewhere_recorded.patient_id IS NOT NULL) THEN true
                      ELSE false
                  END AS vaccinated_elsewhere_recorded_current_year,
                  CASE
                      WHEN (vr_previous.patient_id IS NOT NULL) THEN true
                      ELSE false
                  END AS vaccinated_in_previous_years,
              COALESCE(vr_counts.sais_vaccinations_count, (0)::bigint) AS sais_vaccinations_count,
              vr_recent.most_recent_vaccination_month,
              vr_recent.most_recent_vaccination_year,
              COALESCE(pcs.status, 0) AS consent_status,
              pcs.vaccine_methods AS consent_vaccine_methods,
                  CASE
                      WHEN (parent_refused.patient_id IS NOT NULL) THEN true
                      ELSE false
                  END AS parent_refused_consent_current_year,
                  CASE
                      WHEN (child_refused.patient_id IS NOT NULL) THEN true
                      ELSE false
                  END AS child_refused_vaccination_current_year,
              row_number() OVER (PARTITION BY p.id, prog.id, t.id, s.academic_year ORDER BY patient_school_org.id) AS rn
             FROM ((((((((((((((((((((((((patients p
               JOIN patient_locations pl ON ((pl.patient_id = p.id)))
               JOIN sessions s ON (((s.location_id = pl.location_id) AND (s.academic_year = pl.academic_year))))
               JOIN teams t ON ((t.id = s.team_id)))
               JOIN session_programmes sp ON ((sp.session_id = s.id)))
               JOIN programmes prog ON ((prog.id = sp.programme_id)))
               LEFT JOIN locations school ON ((school.id = p.school_id)))
               LEFT JOIN subteams school_subteam ON ((school_subteam.id = school.subteam_id)))
               LEFT JOIN teams school_team ON ((school_team.id = school_subteam.team_id)))
               LEFT JOIN organisations patient_school_org ON ((patient_school_org.id = school_team.organisation_id)))
               LEFT JOIN local_authorities school_la ON ((school_la.gias_code = school.gias_local_authority_code)))
               LEFT JOIN locations current_location ON ((current_location.id = pl.location_id)))
               LEFT JOIN subteams current_location_subteam ON ((current_location_subteam.id = current_location.subteam_id)))
               LEFT JOIN teams current_location_team ON ((current_location_team.id = current_location_subteam.team_id)))
               LEFT JOIN organisations patient_location_org ON ((patient_location_org.id = current_location_team.organisation_id)))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      vr_s.academic_year
                     FROM (vaccination_records vr
                       JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = ANY (ARRAY[0, 4])))) vr_any ON (((vr_any.patient_id = p.id) AND (vr_any.programme_id = prog.id) AND (vr_any.academic_year = s.academic_year))))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      vr_s.academic_year
                     FROM (vaccination_records vr
                       JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 0))) vr_sais_current ON (((vr_sais_current.patient_id = p.id) AND (vr_sais_current.programme_id = prog.id) AND (vr_sais_current.academic_year = s.academic_year))))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      COALESCE((vr_s.academic_year)::numeric, EXTRACT(year FROM vr.performed_at)) AS academic_year
                     FROM (vaccination_records vr
                       LEFT JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 4))) vr_elsewhere_declared ON (((vr_elsewhere_declared.patient_id = p.id) AND (vr_elsewhere_declared.programme_id = prog.id) AND (vr_elsewhere_declared.academic_year = (s.academic_year)::numeric))))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      EXTRACT(year FROM vr.performed_at) AS academic_year
                     FROM vaccination_records vr
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 0) AND (vr.source = ANY (ARRAY[1, 2])))) vr_elsewhere_recorded ON (((vr_elsewhere_recorded.patient_id = p.id) AND (vr_elsewhere_recorded.programme_id = prog.id) AND (vr_elsewhere_recorded.academic_year = (s.academic_year)::numeric))))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      vr_s.academic_year
                     FROM (vaccination_records vr
                       JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = ANY (ARRAY[0, 4])))) vr_previous ON (((vr_previous.patient_id = p.id) AND (vr_previous.programme_id = prog.id) AND (vr_previous.academic_year < s.academic_year))))
               LEFT JOIN ( SELECT vr.patient_id,
                      vr.programme_id,
                      count(*) AS sais_vaccinations_count
                     FROM vaccination_records vr
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 0))
                    GROUP BY vr.patient_id, vr.programme_id) vr_counts ON (((vr_counts.patient_id = p.id) AND (vr_counts.programme_id = prog.id))))
               LEFT JOIN ( SELECT vr.patient_id,
                      vr.programme_id,
                      vr_s.team_id,
                      EXTRACT(month FROM max(vr.performed_at)) AS most_recent_vaccination_month,
                      EXTRACT(year FROM max(vr.performed_at)) AS most_recent_vaccination_year
                     FROM (vaccination_records vr
                       JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 0))
                    GROUP BY vr.patient_id, vr.programme_id, vr_s.team_id) vr_recent ON (((vr_recent.patient_id = p.id) AND (vr_recent.programme_id = prog.id) AND (vr_recent.team_id = t.id))))
               LEFT JOIN LATERAL ( SELECT pcs_1.status,
                      pcs_1.vaccine_methods
                     FROM patient_consent_statuses pcs_1
                    WHERE ((pcs_1.patient_id = p.id) AND (pcs_1.programme_id = prog.id) AND (pcs_1.academic_year = s.academic_year))
                   LIMIT 1) pcs ON (true))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      COALESCE((vr_s.academic_year)::numeric, EXTRACT(year FROM vr.performed_at)) AS academic_year
                     FROM (vaccination_records vr
                       LEFT JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 1) AND (vr.source = 3))) parent_refused ON (((parent_refused.patient_id = p.id) AND (parent_refused.programme_id = prog.id) AND (parent_refused.academic_year = (s.academic_year)::numeric))))
               LEFT JOIN ( SELECT DISTINCT vr.patient_id,
                      vr.programme_id,
                      vr_s.academic_year
                     FROM (vaccination_records vr
                       JOIN sessions vr_s ON ((vr_s.id = vr.session_id)))
                    WHERE ((vr.discarded_at IS NULL) AND (vr.outcome = 1) AND ((vr.source IS NULL) OR (vr.source <> 3)))) child_refused ON (((child_refused.patient_id = p.id) AND (child_refused.programme_id = prog.id) AND (child_refused.academic_year = s.academic_year))))
            WHERE ((p.invalidated_at IS NULL) AND (p.restricted_at IS NULL))
          )
   SELECT id,
      patient_id,
      patient_gender,
      programme_id,
      programme_type,
      academic_year,
      team_id,
      team_name,
      organisation_id,
      patient_school_local_authority_code,
      patient_local_authority_code,
      patient_school_id,
      patient_school_name,
      session_location_id,
      patient_year_group,
      has_any_vaccination,
      vaccinated_by_sais_current_year,
      vaccinated_elsewhere_declared_current_year,
      vaccinated_elsewhere_recorded_current_year,
      vaccinated_in_previous_years,
      sais_vaccinations_count,
      most_recent_vaccination_month,
      most_recent_vaccination_year,
      consent_status,
      consent_vaccine_methods,
      parent_refused_consent_current_year,
      child_refused_vaccination_current_year
     FROM base_data
    WHERE (rn = 1);
  SQL
  add_index "reporting_api_patient_programme_statuses", ["academic_year", "programme_type"], name: "ix_rapi_pps_year_prog_type"
  add_index "reporting_api_patient_programme_statuses", ["id"], name: "ix_rapi_pps_id", unique: true
  add_index "reporting_api_patient_programme_statuses", ["organisation_id", "academic_year", "programme_type"], name: "ix_rapi_pps_org_year_prog"
  add_index "reporting_api_patient_programme_statuses", ["patient_school_local_authority_code", "programme_type"], name: "ix_rapi_pps_school_la_prog"
  add_index "reporting_api_patient_programme_statuses", ["programme_id", "team_id", "academic_year"], name: "ix_rapi_pps_prog_team_year"
  add_index "reporting_api_patient_programme_statuses", ["team_id", "academic_year"], name: "ix_rapi_pps_team_year"

end
