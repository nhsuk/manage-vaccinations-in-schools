# frozen_string_literal: true

class ReplaceCommonNameWithPreferredNames < ActiveRecord::Migration[7.2]
  def change
    change_table :patients, bulk: true do |t|
      t.remove :common_name, type: :string
      t.string :preferred_given_name
      t.string :preferred_family_name
    end

    change_table :consent_forms, bulk: true do |t|
      t.remove :common_name, type: :string
      t.string :preferred_given_name
      t.string :preferred_family_name
      t.rename :use_common_name, :use_preferred_name
    end
  end
end
