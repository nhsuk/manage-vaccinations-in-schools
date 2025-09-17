# frozen_string_literal: true

class ReplacePatientSessionSessionWithLocation < ActiveRecord::Migration[8.0]
  def up
    change_table :patient_locations, bulk: true do |t|
      t.integer :academic_year
      t.references :location, foreign_key: true
    end

    execute <<-SQL
      UPDATE patient_locations
      SET academic_year = sessions.academic_year, location_id = sessions.location_id
      FROM sessions
      WHERE patient_locations.session_id = sessions.id
    SQL

    change_table :patient_locations, bulk: true do |t|
      t.change_null :academic_year, false
      t.change_null :location_id, false
    end

    remove_column :patient_locations, :session_id

    execute <<-SQL
      DELETE FROM patient_locations a
      USING patient_locations b 
      WHERE a.id > b.id
        AND a.patient_id = b.patient_id
        AND a.location_id = b.location_id
        AND a.academic_year = b.academic_year
    SQL

    add_index :patient_locations, %i[location_id academic_year]

    add_index :patient_locations,
              %i[patient_id location_id academic_year],
              unique: true

    add_index :sessions, %i[location_id academic_year team_id]
  end
end
