# frozen_string_literal: true

class DropProgrammes < ActiveRecord::Migration[8.1]
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

  def up
    SINGLE_COLUMN_TABLES.each { |table| remove_reference table, :programme }

    remove_column :notify_log_entries, :programme_ids

    drop_table :consent_notification_programmes
    drop_table :team_programmes
    drop_table :session_programmes
    drop_table :programmes
  end
end
