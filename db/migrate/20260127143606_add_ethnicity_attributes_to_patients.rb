# frozen_string_literal: true

class AddEthnicityAttributesToPatients < ActiveRecord::Migration[8.1]
  def change
    change_table :patients, bulk: true do |t|
      t.integer :ethnic_group
      t.integer :ethnic_background
      t.string :ethnic_background_other
    end
  end
end
