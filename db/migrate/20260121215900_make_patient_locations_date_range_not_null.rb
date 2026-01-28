# frozen_string_literal: true

class MakePatientLocationsDateRangeNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :patient_locations, :date_range, false
  end
end
