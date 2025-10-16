# frozen_string_literal: true

class AddDelayVaccinationUntilToTriages < ActiveRecord::Migration[8.0]
  def change
    add_column :triages, :delay_vaccination_until, :date
  end
end
