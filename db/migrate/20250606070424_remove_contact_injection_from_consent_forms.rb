# frozen_string_literal: true

class RemoveContactInjectionFromConsentForms < ActiveRecord::Migration[8.0]
  def change
    remove_column :consent_forms, :contact_injection, :boolean
  end
end
