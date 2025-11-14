# frozen_string_literal: true

class MakeProgrammeIdsNull < ActiveRecord::Migration[8.1]
  TABLES = %i[
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

  def change
    TABLES.each { |table| change_column_null table, :programme_id, true }

    change_table :notify_log_entries, bulk: true do |t|
      t.change_null :programme_ids, true
      t.change_default :programme_ids, from: [], to: nil
    end
  end
end
