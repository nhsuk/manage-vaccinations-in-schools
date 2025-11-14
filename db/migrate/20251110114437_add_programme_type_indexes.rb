# frozen_string_literal: true

class AddProgrammeTypeIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :consent_form_programmes,
              %i[programme_type consent_form_id],
              unique: true,
              algorithm: :concurrently
    add_index :consents, :programme_type, algorithm: :concurrently
    add_index :gillick_assessments, :programme_type, algorithm: :concurrently
    add_index :location_programme_year_groups,
              :programme_type,
              algorithm: :concurrently
    add_index :location_programme_year_groups,
              %i[location_year_group_id programme_type],
              unique: true,
              algorithm: :concurrently
    add_index :patient_consent_statuses,
              %i[patient_id programme_type academic_year],
              unique: true,
              algorithm: :concurrently
    add_index :patient_specific_directions,
              :programme_type,
              algorithm: :concurrently
    add_index :patient_triage_statuses,
              %i[patient_id programme_type academic_year],
              unique: true,
              algorithm: :concurrently
    add_index :patient_vaccination_statuses,
              %i[patient_id programme_type academic_year],
              unique: true,
              algorithm: :concurrently
    add_index :pre_screenings, :programme_type, algorithm: :concurrently
    add_index :triages, :programme_type, algorithm: :concurrently
    add_index :vaccination_records,
              %i[patient_id programme_type outcome],
              where: "discarded_at IS NULL",
              algorithm: :concurrently
    add_index :vaccination_records, :programme_type, algorithm: :concurrently
    add_index :vaccines, :programme_type, algorithm: :concurrently
  end
end
