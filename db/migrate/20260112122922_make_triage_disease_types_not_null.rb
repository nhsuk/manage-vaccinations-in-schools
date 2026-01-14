# frozen_string_literal: true

class MakeTriageDiseaseTypesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :triages, :disease_types, false
  end
end
