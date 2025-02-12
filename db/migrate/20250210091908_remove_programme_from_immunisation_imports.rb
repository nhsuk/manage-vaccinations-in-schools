# frozen_string_literal: true

class RemoveProgrammeFromImmunisationImports < ActiveRecord::Migration[8.0]
  def change
    remove_reference :immunisation_imports,
                     :programme,
                     foreign_key: true,
                     null: false
  end
end
