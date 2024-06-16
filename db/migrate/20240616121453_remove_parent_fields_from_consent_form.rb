class RemoveParentFieldsFromConsentForm < ActiveRecord::Migration[7.1]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.remove :parent_email, type: :string
      t.remove :parent_name, type: :string
      t.remove :parent_phone, type: :string
      t.remove :parent_relationship, type: :integer
      t.remove :parent_relationship_other, type: :string
      t.remove :contact_method, type: :integer
      t.remove :contact_method_other, type: :text
    end
  end
end
