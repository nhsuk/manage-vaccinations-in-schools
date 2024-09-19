# frozen_string_literal: true

class RenameCohortReceptionStartingYear < ActiveRecord::Migration[7.2]
  def change
    rename_column :cohorts, :reception_starting_year, :birth_academic_year
  end
end
