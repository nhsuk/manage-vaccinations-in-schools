# frozen_string_literal: true

class RemoveUnusedConsentColumns < ActiveRecord::Migration[7.1]
  def change
    change_table :consents, bulk: true do |t|
      t.remove :childs_dob, type: :text
      t.remove :childs_name, type: :text
      t.remove :common_name, type: :text
      t.remove :address_line_1, type: :text
      t.remove :address_line_2, type: :text
      t.remove :address_postcode, type: :text
      t.remove :address_town, type: :text
      t.remove :gp_name, type: :text
      t.remove :gp_response, type: :integer
    end
  end
end
