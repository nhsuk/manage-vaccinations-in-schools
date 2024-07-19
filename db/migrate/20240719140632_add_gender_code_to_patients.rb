# frozen_string_literal: true

class AddGenderCodeToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :gender_code, :integer, default: 0, null: false
  end
end
