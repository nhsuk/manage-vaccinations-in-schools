# frozen_string_literal: true

class AddDateOfDeathToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :date_of_death, :date
  end
end
