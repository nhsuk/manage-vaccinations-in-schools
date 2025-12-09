# frozen_string_literal: true

class AddAlternativeNameToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :alternative_name, :text

    reversible do |dir|
      dir.up do
        Location.generic_clinic.update_all(
          alternative_name: "No known school (including home-schooled children)"
        )
      end
    end
  end
end
