# frozen_string_literal: true

class AddDoseSequenceToPatientVaccinationStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :patient_vaccination_statuses, :dose_sequence, :integer
  end
end
