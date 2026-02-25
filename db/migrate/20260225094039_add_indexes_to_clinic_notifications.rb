# frozen_string_literal: true

class AddIndexesToClinicNotifications < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_table :clinic_notifications, bulk: true do |t|
      t.index :academic_year, algorithm: :concurrently
      t.index :programme_types, using: :gin, algorithm: :concurrently
    end
  end
end
