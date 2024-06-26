# frozen_string_literal: true

class AddPatientSessionIdToTriage < ActiveRecord::Migration[7.0]
  def change
    add_reference :triage, :patient_session, foreign_key: true
  end
end
