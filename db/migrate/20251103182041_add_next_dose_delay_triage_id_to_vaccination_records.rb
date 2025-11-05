# frozen_string_literal: true

class AddNextDoseDelayTriageIdToVaccinationRecords < ActiveRecord::Migration[
  8.0
]
  def change
    add_reference :vaccination_records,
                  :next_dose_delay_triage,
                  null: true,
                  foreign_key: {
                    to_table: :triages
                  }
  end
end
