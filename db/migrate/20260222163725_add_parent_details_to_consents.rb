# frozen_string_literal: true

class AddParentDetailsToConsents < ActiveRecord::Migration[8.0]
  def change
    change_table :consents, bulk: true do |t|
      t.string :parent_full_name
      t.string :parent_email
      t.string :parent_phone
      t.boolean :parent_phone_receive_updates
      t.string :parent_relationship_type
      t.string :parent_relationship_other_name
    end
  end
end
