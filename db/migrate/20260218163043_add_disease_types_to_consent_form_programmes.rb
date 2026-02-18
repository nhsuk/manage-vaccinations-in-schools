# frozen_string_literal: true

class AddDiseaseTypesToConsentFormProgrammes < ActiveRecord::Migration[8.1]
  def change
    add_column :consent_form_programmes,
               :disease_types,
               :enum,
               enum_type: :disease_type,
               array: true
  end
end
