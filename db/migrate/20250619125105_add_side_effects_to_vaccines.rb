# frozen_string_literal: true

class AddSideEffectsToVaccines < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccines,
               :side_effects,
               :integer,
               array: true,
               default: [],
               null: false
  end
end
