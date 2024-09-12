# frozen_string_literal: true

class ChangeParentContactMethod < ActiveRecord::Migration[7.2]
  def change
    change_table :parents, bulk: true do |t|
      t.remove :contact_method, type: :integer
      t.string :contact_method_type
      t.rename :contact_method_other, :contact_method_other_details
    end
  end
end
