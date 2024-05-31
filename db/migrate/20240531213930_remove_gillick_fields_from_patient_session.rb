class RemoveGillickFieldsFromPatientSession < ActiveRecord::Migration[7.1]
  def up
    change_table :patient_sessions, bulk: true do |t|
      t.remove :gillick_competence_assessor_user_id, :bigint
      t.remove :gillick_competent, :boolean
      t.remove :gillick_competence_notes, :text
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
