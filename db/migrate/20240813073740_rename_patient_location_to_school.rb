# frozen_string_literal: true

class RenamePatientLocationToSchool < ActiveRecord::Migration[7.1]
  def change
    rename_column :patients, :location_id, :school_id
  end
end
