# frozen_string_literal: true

class AddWithoutGelatineToConsents < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_form_programmes, :without_gelatine, :boolean
    add_column :consents, :without_gelatine, :boolean
    add_column :patient_consent_statuses, :without_gelatine, :boolean
  end
end
