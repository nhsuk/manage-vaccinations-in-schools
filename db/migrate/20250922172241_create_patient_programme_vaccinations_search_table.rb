# frozen_string_literal: true

class CreatePatientProgrammeVaccinationsSearchTable < ActiveRecord::Migration[
  8.0
]
  def change
    create_table :patient_programme_vaccinations_searches do |t|
      t.references :patient, null: false, foreign_key: true
      t.enum "programme_type", null: false, enum_type: "programme_type"
      t.datetime :last_searched_at, null: false

      t.timestamps

      t.index :last_searched_at
      t.index :programme_type
    end
  end
end
