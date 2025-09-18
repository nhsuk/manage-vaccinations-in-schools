# frozen_string_literal: true

class AddVaccinationRecordDiscoveredSentAtToConsents < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :consents,
               :vaccination_record_discovered_sent_at,
               :datetime,
               null: true
  end
end
