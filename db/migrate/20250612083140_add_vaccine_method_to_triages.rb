# frozen_string_literal: true

class AddVaccineMethodToTriages < ActiveRecord::Migration[8.0]
  def change
    add_column :triage, :vaccine_method, :integer
  end
end
