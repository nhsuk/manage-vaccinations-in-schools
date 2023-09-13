class AddGpFieldsToConsentForm < ActiveRecord::Migration[7.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.string :gp_name
      t.integer :gp_response
    end
  end
end
