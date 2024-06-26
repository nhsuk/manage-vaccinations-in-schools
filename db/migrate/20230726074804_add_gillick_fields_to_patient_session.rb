# frozen_string_literal: true

class AddGillickFieldsToPatientSession < ActiveRecord::Migration[7.0]
  def change
    change_table :patient_sessions, bulk: true do |t|
      t.boolean :gillick_competent
      t.text :gillick_competence_notes
    end
  end
end
