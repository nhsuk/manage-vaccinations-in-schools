# frozen_string_literal: true

class AddAboutParentFieldsToConsentForm < ActiveRecord::Migration[7.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.string :parent_name
      t.integer :parent_relationship
      t.string :parent_relationship_other
      t.string :parent_email
      t.string :parent_phone
      t.integer :contact_method
      t.text :contact_method_other
    end
  end
end
