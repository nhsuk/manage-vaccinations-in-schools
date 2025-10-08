# frozen_string_literal: true

class AddLocationYearGroupToLocationProgrammeYearGroups < ActiveRecord::Migration[
  8.0
]
  def change
    change_table :location_programme_year_groups, bulk: true do |t|
      t.references :location_year_group, foreign_key: { on_delete: :cascade }
      t.index %i[location_year_group_id programme_id], unique: true
    end

    reversible { |direction| direction.up { execute <<-SQL } }
      UPDATE location_programme_year_groups
      SET location_year_group_id = location_year_groups.id
      FROM location_year_groups
      WHERE location_year_groups.location_id = location_programme_year_groups.location_id
      AND location_year_groups.academic_year = location_programme_year_groups.academic_year
      AND location_year_groups.value = location_programme_year_groups.year_group
    SQL

    change_column_null :location_programme_year_groups,
                       :location_year_group_id,
                       false
  end
end
