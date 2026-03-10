# frozen_string_literal: true

class CreateVaccinationReportExports < ActiveRecord::Migration[8.1]
  def change
    create_table :vaccination_report_exports, id: :uuid do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :programme_type, null: false
      t.integer :academic_year, null: false
      t.date :date_from
      t.date :date_to
      t.string :file_format, null: false
      t.datetime :expired_at

      t.timestamps
    end

    add_index :vaccination_report_exports, :status
    add_index :vaccination_report_exports, :created_at
  end
end
