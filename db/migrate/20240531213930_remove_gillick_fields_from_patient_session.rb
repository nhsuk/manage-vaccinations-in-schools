# frozen_string_literal: true

class RemoveGillickFieldsFromPatientSession < ActiveRecord::Migration[7.1]
  def up
    change_table :patient_sessions, bulk: true do |t|
      t.remove :gillick_competence_assessor_user_id,
               :gillick_competent,
               :gillick_competence_notes
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
