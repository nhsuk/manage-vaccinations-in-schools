# frozen_string_literal: true

class AddContactInjectionToConsentForm < ActiveRecord::Migration[7.0]
  def change
    add_column :consent_forms, :contact_injection, :boolean
  end
end
