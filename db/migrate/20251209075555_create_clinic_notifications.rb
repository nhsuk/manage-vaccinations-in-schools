# frozen_string_literal: true

class CreateClinicNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :clinic_notifications do |t|
      t.references :patient, foreign_key: true, null: false
      t.references :team, foreign_key: true, null: false
      t.integer :academic_year, null: false
      t.integer :type, null: false
      t.datetime :sent_at, null: false
      t.enum :programme_types,
             array: true,
             enum_type: :programme_type,
             null: false
      t.references :sent_by_user, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
