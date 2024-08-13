# frozen_string_literal: true

class AddHomeEducatedToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :home_educated, :boolean
  end
end
