# frozen_string_literal: true

class RenamePatientColumns < ActiveRecord::Migration[7.1]
  def up
    change_table :patients, bulk: true do |t|
      t.change :first_name, :string
      t.change :last_name, :string
      t.change :preferred_name, :string
      t.change :parent_email, :string
      t.change :parent_name, :string
      t.change :parent_phone, :string
      t.change :parent_relationship_other, :string

      t.rename :dob, :date_of_birth
      t.rename :preferred_name, :common_name
    end
  end

  def down
    change_table :patients, bulk: true do |t|
      t.change :first_name, :text
      t.change :last_name, :text
      t.change :common_name, :text
      t.change :parent_email, :text
      t.change :parent_name, :text
      t.change :parent_phone, :text
      t.change :parent_relationship_other, :text

      t.rename :date_of_birth, :dob
      t.rename :common_name, :preferred_name
    end
  end
end
