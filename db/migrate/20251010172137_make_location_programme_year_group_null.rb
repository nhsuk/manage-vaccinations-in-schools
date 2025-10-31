# frozen_string_literal: true

class MakeLocationProgrammeYearGroupNull < ActiveRecord::Migration[8.0]
  def change
    change_table :location_programme_year_groups, bulk: true do |t|
      t.change_null :location_id, true
      t.change_null :academic_year, true
      t.change_null :year_group, true
    end
  end
end
