# frozen_string_literal: true

class RemoveUniqueIndexOnGillickAssessment < ActiveRecord::Migration[7.2]
  def change
    remove_index :gillick_assessments, :patient_session_id, unique: true
    add_index :gillick_assessments, :patient_session_id
  end
end
