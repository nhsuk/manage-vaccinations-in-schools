# frozen_string_literal: true

class AddWithoutGelatineToTriages < ActiveRecord::Migration[8.0]
  def change
    add_column :triages, :without_gelatine, :boolean
    add_column :patient_triage_statuses, :without_gelatine, :boolean
  end
end
