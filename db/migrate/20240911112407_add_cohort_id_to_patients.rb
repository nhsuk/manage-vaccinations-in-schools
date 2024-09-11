# frozen_string_literal: true

class AddCohortIdToPatients < ActiveRecord::Migration[7.2]
  def change
    add_reference :patients, :cohort, foreign_key: true
  end
end
