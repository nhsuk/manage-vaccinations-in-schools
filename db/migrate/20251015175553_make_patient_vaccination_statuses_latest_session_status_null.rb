# frozen_string_literal: true

class MakePatientVaccinationStatusesLatestSessionStatusNull < ActiveRecord::Migration[
  8.0
]
  def change
    change_table :patient_vaccination_statuses, bulk: true do |t|
      t.change_null :latest_session_status, true
      t.change_default :latest_session_status, from: 0, to: nil
    end
  end
end
