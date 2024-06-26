# frozen_string_literal: true

class AddSentConsentAtToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :sent_consent_at, :datetime
  end
end
