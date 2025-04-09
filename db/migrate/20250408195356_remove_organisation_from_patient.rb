# frozen_string_literal: true

class RemoveOrganisationFromPatient < ActiveRecord::Migration[8.0]
  def change
    remove_reference :patients, :organisation, foreign_key: true
  end
end
