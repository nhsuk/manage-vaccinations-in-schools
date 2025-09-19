# frozen_string_literal: true

class AddForeignKeyCascadeToJoinTables < ActiveRecord::Migration[8.0]
  FOREIGN_KEYS = [
    %w[batches_immunisation_imports batches],
    %w[batches_immunisation_imports immunisation_imports],
    %w[class_imports_parent_relationships class_imports],
    %w[class_imports_parent_relationships parent_relationships],
    %w[class_imports_parents class_imports],
    %w[class_imports_parents parents],
    %w[class_imports_patients class_imports],
    %w[class_imports_patients patients],
    %w[cohort_imports_parent_relationships cohort_imports],
    %w[cohort_imports_parent_relationships parent_relationships],
    %w[cohort_imports_parents cohort_imports],
    %w[cohort_imports_parents parents],
    %w[cohort_imports_patients cohort_imports],
    %w[cohort_imports_patients patients],
    %w[consent_form_programmes consent_forms],
    %w[consent_form_programmes programmes],
    %w[immunisation_imports_patient_locations immunisation_imports],
    %w[immunisation_imports_patient_locations patient_locations],
    %w[immunisation_imports_patients immunisation_imports],
    %w[immunisation_imports_patients patients],
    %w[immunisation_imports_sessions immunisation_imports],
    %w[immunisation_imports_sessions sessions],
    %w[immunisation_imports_vaccination_records immunisation_imports],
    %w[immunisation_imports_vaccination_records vaccination_records]
  ].freeze

  def change
    FOREIGN_KEYS.each do |foreign_key|
      remove_foreign_key foreign_key.first, foreign_key.last
      add_foreign_key foreign_key.first, foreign_key.last, on_delete: :cascade
    end
  end
end
