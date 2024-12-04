# frozen_string_literal: true

class RemoveGPFromConsentForms < ActiveRecord::Migration[7.2]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.remove :gp_name, type: :string
      t.remove :gp_response, type: :integer
    end
  end
end
