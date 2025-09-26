# frozen_string_literal: true

class AddAcademicYearToLocationProgrammeYearGroups < ActiveRecord::Migration[
  8.0
]
  def change
    # rubocop:disable Rails/BulkChangeTable
    change_table :location_programme_year_groups do |t|
      t.integer :academic_year, null: false, default: 2025
      t.change_default :academic_year, from: 2025, to: nil
    end
    # rubocop:enable Rails/BulkChangeTable

    remove_index :location_programme_year_groups,
                 %i[location_id programme_id year_group],
                 unique: true

    add_index :location_programme_year_groups,
              %i[location_id academic_year programme_id year_group],
              unique: true

    # this is not needed due to leftmost index rule
    remove_index :location_programme_year_groups, :location_id
  end
end
