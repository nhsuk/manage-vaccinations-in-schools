# frozen_string_literal: true

class RenamePatientFirstAndLastName < ActiveRecord::Migration[7.2]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.rename :first_name, :given_name
      t.rename :last_name, :family_name
    end

    change_table :patients, bulk: true do |t|
      t.rename :first_name, :given_name
      t.rename :last_name, :family_name
    end
  end
end
