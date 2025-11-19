# frozen_string_literal: true

class AddTeamLocationToConsentFormsAndSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :consent_forms, :team_location, foreign_key: true
    add_reference :sessions, :team_location, foreign_key: true
  end
end
