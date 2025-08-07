# frozen_string_literal: true

class AddLatestSessionStatusToVaccinationStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :patient_vaccination_statuses,
               :latest_session_status,
               :integer,
               null: false,
               default: 0
  end
end
