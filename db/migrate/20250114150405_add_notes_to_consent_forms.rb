# frozen_string_literal: true

class AddNotesToConsentForms < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_forms, :notes, :text, null: false, default: ""
  end
end
