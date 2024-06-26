# frozen_string_literal: true

class RemoveGpFieldFromPatient < ActiveRecord::Migration[7.0]
  def change
    remove_column :patients, :gp, :string
  end
end
