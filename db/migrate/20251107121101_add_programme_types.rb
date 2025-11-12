# frozen_string_literal: true

class AddProgrammeTypes < ActiveRecord::Migration[8.1]
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

  ARRAY_COLUMN_TABLES = %i[
    consent_notifications
    notify_log_entries
    teams
    sessions
  ].freeze

  def change
    SINGLE_COLUMN_TABLES.each do |table|
      add_column table, :programme_type, :enum, enum_type: :programme_type
    end

    ARRAY_COLUMN_TABLES.each do |table|
      change_table table, bulk: true do |t|
        t.enum :programme_types, enum_type: :programme_type, array: true
        t.index :programme_types, using: :gin
      end
    end
  end
end
