# frozen_string_literal: true

class RemoveLocationProgrammeYearGroupColumns < ActiveRecord::Migration[8.0]
  def change
    change_table :location_programme_year_groups, bulk: true do |t|
      t.remove_references :location
      t.remove :academic_year, :year_group, type: :integer
    end
  end
end
