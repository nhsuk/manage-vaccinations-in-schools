# frozen_string_literal: true

class MakeVaccinationRecordDiseaseTypesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :vaccination_records, :disease_types, false
  end
end
