# frozen_string_literal: true

class AddConsentIdToConsentForm < ActiveRecord::Migration[7.1]
  def change
    add_reference :consent_forms, :consent, foreign_key: true
  end
end
