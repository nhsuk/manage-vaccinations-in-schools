# frozen_string_literal: true

class AddLocationYearGroupToLocationProgrammeYearGroups < ActiveRecord::Migration[
  8.0
]
  def change
    backfill_missing_location_year_groups

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

  def backfill_missing_location_year_groups
    sql = <<~SQL
      SELECT
          lpyg.location_id,
          lpyg.academic_year,
          ARRAY_AGG(DISTINCT lpyg.year_group ORDER BY lpyg.year_group) AS missing_year_groups
      FROM
          location_programme_year_groups lpyg
              LEFT JOIN location_year_groups lyg
                        ON lpyg.location_id = lyg.location_id
                            AND lpyg.academic_year = lyg.academic_year
                            AND lpyg.year_group = lyg.value
      WHERE
          lyg.id IS NULL
      GROUP BY
          lpyg.location_id,
          lpyg.academic_year
      ORDER BY
          lpyg.location_id,
          lpyg.academic_year;
    SQL

    result = ActiveRecord::Base.connection.execute(sql)

    result.each do |row|
      location_id = row["location_id"]
      academic_year = row["academic_year"]
      year_groups =
        row["missing_year_groups"].gsub(/[{}]/, "").split(",").map(&:to_i)

      Rails.logger.debug "Location #{location_id} (#{academic_year}): #{year_groups.inspect}"

      Location.find(location_id).import_year_groups!(
        year_groups,
        academic_year: academic_year,
        source: "gias"
      )
    end
  end
end
