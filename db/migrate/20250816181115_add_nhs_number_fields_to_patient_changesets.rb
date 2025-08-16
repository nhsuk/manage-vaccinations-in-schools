# frozen_string_literal: true

class AddNHSNumberFieldsToPatientChangesets < ActiveRecord::Migration[8.0]
  def change
    change_table :patient_changesets, bulk: true do |t|
      t.string :uploaded_nhs_number
      t.string :pds_nhs_number
      t.boolean :matched_on_nhs_number
    end
  end
end
