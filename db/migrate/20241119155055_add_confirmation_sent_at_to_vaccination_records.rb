# frozen_string_literal: true

class AddConfirmationSentAtToVaccinationRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :vaccination_records, :confirmation_sent_at, :datetime
  end
end
