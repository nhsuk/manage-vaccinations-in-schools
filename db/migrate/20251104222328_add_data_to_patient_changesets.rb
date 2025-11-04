# frozen_string_literal: true

class AddDataToPatientChangesets < ActiveRecord::Migration[8.1]
  def change
    change_table :patient_changesets, bulk: true do |t|
      t.jsonb :data
      t.integer :record_type, null: false, default: 1
      t.change_null :row_number, true
    end

    PatientChangeset.find_each do |changeset|
      old_data = changeset.pending_changes

      next unless old_data.is_a?(Hash)

      new_data = {
        upload: {
          child: old_data["child"] || {},
          parent_1: old_data["parent_1"] || {},
          parent_2: old_data["parent_2"] || {},
          academic_year: old_data["academic_year"],
          home_educated: old_data["home_educated"],
          school_move_source: old_data["school_move_source"]
        },
        search_results: old_data["search_results"] || [],
        review: {
          patient: {
          },
          school_move: {
          }
        }
      }

      changeset.update_columns(data: new_data, pending_changes: new_data)
    end
  end
end
