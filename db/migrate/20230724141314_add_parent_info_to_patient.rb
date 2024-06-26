# frozen_string_literal: true

class AddParentInfoToPatient < ActiveRecord::Migration[7.0]
  def change
    change_table :patients, bulk: true do |t|
      t.text :parent_name
      t.integer :parent_relationship
      t.text :parent_relationship_other
      t.text :parent_email
      t.text :parent_phone
      t.text :parent_info_source
    end
  end
end
