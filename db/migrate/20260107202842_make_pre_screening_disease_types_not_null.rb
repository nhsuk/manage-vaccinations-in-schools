# frozen_string_literal: true

class MakePreScreeningDiseaseTypesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :pre_screenings, :disease_types, false
  end
end
