# frozen_string_literal: true

class AddDateRangeToPatientLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :patient_locations,
               :date_range,
               :daterange,
               default: Range.new(nil, nil)
  end
end
