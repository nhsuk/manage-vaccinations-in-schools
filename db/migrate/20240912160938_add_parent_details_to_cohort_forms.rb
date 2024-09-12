# frozen_string_literal: true

class AddParentDetailsToCohortForms < ActiveRecord::Migration[7.2]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.string :parent_contact_method_other_details
      t.string :parent_contact_method_type
      t.string :parent_email
      t.string :parent_name
      t.string :parent_phone
      t.string :parent_relationship_other_name
      t.string :parent_relationship_type
      t.remove_references :parent
    end
  end
end
