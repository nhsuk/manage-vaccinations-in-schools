# frozen_string_literal: true

class AddOriginalNamesToPatients < ActiveRecord::Migration[7.2]
  def up
    change_table :patients, bulk: true do |t|
      t.string :original_family_name
      t.string :original_given_name
    end

    Patient.update_all(
      "original_family_name = family_name, original_given_name = given_name"
    )

    change_table :patients, bulk: true do |t|
      t.change_null :original_family_name, false
      t.change_null :original_given_name, false
    end
  end

  def down
    change_table :patients, bulk: true do |t|
      t.remove :original_family_name, :original_given_name
    end
  end
end
