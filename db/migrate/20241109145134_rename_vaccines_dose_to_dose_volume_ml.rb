# frozen_string_literal: true

class RenameVaccinesDoseToDoseVolumeMl < ActiveRecord::Migration[7.2]
  def change
    rename_column :vaccines, :dose, :dose_volume_ml
  end
end
