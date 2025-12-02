# frozen_string_literal: true

class RemoveTeamLocationAcademicYearFromSessionsAndConsentForms < ActiveRecord::Migration[
  8.1
]
  def up
    change_table :consent_forms, bulk: true do |t|
      t.remove_references :team, :location
      t.remove :academic_year, type: :integer
    end

    change_table :sessions, bulk: true do |t|
      t.remove_references :team, :location
      t.remove :academic_year, type: :integer
    end
  end
end
