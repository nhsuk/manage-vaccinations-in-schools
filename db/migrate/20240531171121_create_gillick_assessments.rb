class CreateGillickAssessments < ActiveRecord::Migration[7.1]
  def change
    create_table :gillick_assessments do |t|
      t.boolean :gillick_competent
      t.text :notes
      t.datetime :recorded_at
      t.references :assessor_user,
                   null: false,
                   foreign_key: {
                     to_table: :users
                   }
      t.references :patient_session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
