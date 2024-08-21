# frozen_string_literal: true

class MakeTriageColumnsRequired < ActiveRecord::Migration[7.1]
  def change
    Triage.where(notes: nil).update_all(notes: "")

    change_table :triage, bulk: true do |t|
      t.change_default :notes, from: nil, to: ""
      t.change_null :notes, false

      t.change_null :status, false
      t.change_null :patient_session_id, false
      t.change_null :performed_by_user_id, false
    end
  end
end
