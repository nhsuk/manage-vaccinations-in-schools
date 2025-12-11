# frozen_string_literal: true

class MakeVaccineUploadNameNotNull < ActiveRecord::Migration[8.1]
  def change
    change_table :vaccines, bulk: true do |t|
      t.change_null :upload_name, false
      t.change_null :nivs_name, true
    end

    remove_index :vaccines,
                 column: :nivs_name,
                 name: "index_vaccines_on_nivs_name",
                 unique: true
    add_index :vaccines, :upload_name, unique: true
  end
end
