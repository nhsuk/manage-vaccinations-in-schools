# frozen_string_literal: true

class AddDatabasePerformanceIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :archive_reasons,
              %i[patient_id team_id],
              algorithm: :concurrently,
              unique: true

    add_index :patient_locations,
              %i[location_id academic_year patient_id],
              algorithm: :concurrently,
              unique: true

    add_index :school_moves, %i[patient_id school_id], algorithm: :concurrently

    add_index :sessions,
              %i[academic_year location_id team_id],
              algorithm: :concurrently

    add_index :vaccination_records,
              %i[patient_id session_id],
              algorithm: :concurrently

    add_index :vaccination_records,
              %i[performed_ods_code patient_id],
              algorithm: :concurrently,
              where: "(session_id IS NULL)"
  end
end
