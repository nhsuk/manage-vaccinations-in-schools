# frozen_string_literal: true

class AddLocationIdToPatients < ActiveRecord::Migration[7.1]
  def change
    add_reference :patients, :location, foreign_key: true
  end
end
