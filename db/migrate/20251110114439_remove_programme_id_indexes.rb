# frozen_string_literal: true

class RemoveProgrammeIdIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :consent_form_programmes,
                 %i[programme_id consent_form_id],
                 unique: true
    remove_index :consents, :programme_id
    remove_index :gillick_assessments, :programme_id
    remove_index :location_programme_year_groups, :programme_id
    remove_index :location_programme_year_groups,
                 %i[location_year_group_id programme_id],
                 unique: true
    remove_index :patient_consent_statuses,
                 %i[patient_id programme_id academic_year],
                 unique: true
    remove_index :patient_specific_directions, :programme_id
    remove_index :patient_triage_statuses,
                 %i[patient_id programme_id academic_year],
                 unique: true
    remove_index :patient_vaccination_statuses,
                 %i[patient_id programme_id academic_year],
                 unique: true
    remove_index :pre_screenings, :programme_id
    remove_index :triages, :programme_id
    remove_index :vaccination_records,
                 %i[patient_id programme_id outcome],
                 where: "discarded_at IS NULL"
    remove_index :vaccination_records, :programme_id
    remove_index :vaccines, :programme_id
  end
end
