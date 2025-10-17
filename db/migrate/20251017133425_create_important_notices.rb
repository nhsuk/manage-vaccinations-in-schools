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
      t.integer :notice_type, null: false
      t.text :message
      t.datetime :date_time
      t.boolean :can_dismiss, default: false
      t.datetime :dismissed_at

      t.timestamps
    end

    add_index :important_notices,
              %i[patient_id notice_type date_time team_id],
              unique: true,
              name: "index_notices_on_patient_and_type_and_datetime_and_team"
  end
end
