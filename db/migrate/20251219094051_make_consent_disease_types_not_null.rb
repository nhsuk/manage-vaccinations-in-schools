# frozen_string_literal: true

class MakeConsentDiseaseTypesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :consents, :disease_types, false
  end
end
