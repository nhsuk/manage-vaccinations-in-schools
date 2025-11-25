# frozen_string_literal: true

class CreateImportantNotices < ActiveRecord::Migration[8.0]
  def change
    create_table :important_notices do |t|
      t.references :patient, foreign_key: true, null: false
      t.references :team, foreign_key: true, null: false
      t.references :vaccination_record, foreign_key: true, null: true
      t.references :dismissed_by_user,
                   foreign_key: {
                     to_table: :users
                   },
                   null: true
      t.integer :type, null: false
      t.datetime :recorded_at, null: false
      t.datetime :dismissed_at

      t.timestamps
    end

    add_index :important_notices,
              %i[patient_id type recorded_at team_id],
              unique: true,
              name: "index_notices_on_patient_and_type_and_recorded_at_and_team"
  end
end
