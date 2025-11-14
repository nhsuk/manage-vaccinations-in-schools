# frozen_string_literal: true

class MakeProgrammeTypesNotNull < ActiveRecord::Migration[8.1]
  SINGLE_COLUMN_TABLES = %i[
    consent_form_programmes
    consents
    gillick_assessments
    location_programme_year_groups
    patient_consent_statuses
    patient_specific_directions
    patient_triage_statuses
    patient_vaccination_statuses
    pre_screenings
    triages
    vaccination_records
    vaccines
  ].freeze

  ARRAY_COLUMN_TABLES = %i[consent_notifications teams sessions].freeze

  def change
    SINGLE_COLUMN_TABLES.each do |table|
      change_column_null table, :programme_type, false
    end

    ARRAY_COLUMN_TABLES.each do |table|
      change_column_null table, :programme_types, false
    end

    change_table :notify_log_entries, bulk: true do |t|
      t.change_default :programme_types, from: nil, to: []
      t.change_null :programme_types, false
    end
  end
end
