# frozen_string_literal: true

class AddConfirmationSentAtToConsentForms < ActiveRecord::Migration[8.1]
  def change
    add_column :consent_forms, :confirmation_sent_at, :datetime
  end
end
