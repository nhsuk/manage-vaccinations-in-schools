# frozen_string_literal: true

class AddLocalPatientIdAndUriToVaccinationRecord < ActiveRecord::Migration[8.1]
  def change
    change_table :vaccination_records do |t|
      t.string :local_patient_id, :local_patient_id_uri
    end
  end
end
