# frozen_string_literal: true

class RemoveAcademicYearFromCohorts < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/NotNullColumn
    change_table :cohorts, bulk: true do |t|
      t.remove_index %i[team_id academic_year year_group], unique: true
      t.remove :academic_year, type: :integer, null: false
      t.rename :year_group, :reception_starting_year
      t.index %i[team_id reception_starting_year], unique: true
    end
    # rubocop:enable Rails/NotNullColumn
  end
end
