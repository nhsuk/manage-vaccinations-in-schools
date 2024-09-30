# frozen_string_literal: true

class RemoveConsentRequestSentAtFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :consent_request_sent_at, :datetime
  end
end
