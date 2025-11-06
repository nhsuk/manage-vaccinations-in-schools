# frozen_string_literal: true

class AddIndexesToPatientStatuses < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :patient_consent_statuses,
              %i[academic_year patient_id],
              algorithm: :concurrently
    add_index :patient_triage_statuses,
              %i[academic_year patient_id],
              algorithm: :concurrently
    add_index :patient_vaccination_statuses,
              %i[academic_year patient_id],
              algorithm: :concurrently
  end
end
