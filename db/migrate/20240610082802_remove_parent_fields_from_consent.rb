# frozen_string_literal: true

class RemoveParentFieldsFromConsent < ActiveRecord::Migration[7.1]
  def change
    change_table :consents, bulk: true do |t|
      t.remove :parent_email, type: :string
      t.remove :parent_name, type: :string
      t.remove :parent_phone, type: :string
      t.remove :parent_relationship, type: :integer
      t.remove :parent_relationship_other, type: :string
      t.remove :parent_contact_method, type: :integer
      t.remove :parent_contact_method_other, type: :text
    end
  end
end
