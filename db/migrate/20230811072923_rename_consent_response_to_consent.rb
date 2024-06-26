# frozen_string_literal: true

class RenameConsentResponseToConsent < ActiveRecord::Migration[7.0]
  def change
    rename_table :consent_responses, :consents
  end
end
