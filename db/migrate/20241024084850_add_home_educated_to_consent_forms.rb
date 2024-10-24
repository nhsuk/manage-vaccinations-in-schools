# frozen_string_literal: true

class AddHomeEducatedToConsentForms < ActiveRecord::Migration[7.2]
  def change
    add_column :consent_forms, :home_educated, :boolean
  end
end
