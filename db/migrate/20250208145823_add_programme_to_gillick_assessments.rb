# frozen_string_literal: true

class AddProgrammeToGillickAssessments < ActiveRecord::Migration[8.0]
  def up
    add_reference :gillick_assessments, :programme, foreign_key: true

    GillickAssessment
      .includes(patient_session: :programmes)
      .find_each do |gillick_assessment|
        programme_id = gillick_assessment.patient_session.programmes.first.id
        gillick_assessment.update!(programme_id:)
      end

    change_column_null :gillick_assessments, :programme_id, false
  end

  def down
    remove_reference :gillick_assessments, :programme
  end
end
