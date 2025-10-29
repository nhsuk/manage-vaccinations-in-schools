# frozen_string_literal: true

class CreatePatientProgrammeVaccinationsSearchTable < ActiveRecord::Migration[
  8.0
]
  def change
    create_table :patient_programme_vaccinations_searches do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :programme, null: false, foreign_key: true
      t.datetime :last_searched_at, null: false

      t.timestamps

      t.index %i[last_searched_at]
    end
  end
end
