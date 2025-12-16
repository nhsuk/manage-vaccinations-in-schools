# frozen_string_literal: true

class AddDiseaseTypesToPatientProgrammeStatuses < ActiveRecord::Migration[8.1]
  def change
    add_column :patient_programme_statuses,
               :disease_types,
               :enum,
               enum_type: :disease_type,
               array: true
  end
end
