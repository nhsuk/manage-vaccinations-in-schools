# frozen_string_literal: true

class MakeSessionAndConsentFormTeamLocationNotNull < ActiveRecord::Migration[
  8.1
]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.change_null :team_location_id, false
      t.change_null :team_id, true
      t.change_null :location_id, true
      t.change_null :academic_year, true
    end

    change_table :sessions, bulk: true do |t|
      t.change_null :team_location_id, false
      t.change_null :team_id, true
      t.change_null :location_id, true
      t.change_null :academic_year, true
    end
  end
end
