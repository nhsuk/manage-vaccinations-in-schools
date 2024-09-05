# frozen_string_literal: true

class AddActiveToPatientSessions < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :patient_sessions, :active, :boolean, default: true, null: false
    change_column_default :patient_sessions, :active, from: true, to: false
    # rubocop:enable Rails/BulkChangeTable
  end
end
