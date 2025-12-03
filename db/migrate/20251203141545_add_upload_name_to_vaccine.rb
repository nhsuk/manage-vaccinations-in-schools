# frozen_string_literal: true

class AddUploadNameToVaccine < ActiveRecord::Migration[8.1]
  def change
    add_column :vaccines, :upload_name, :text
  end
end
