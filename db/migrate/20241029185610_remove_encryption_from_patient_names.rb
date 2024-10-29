# frozen_string_literal: true

class RemoveEncryptionFromPatientNames < ActiveRecord::Migration[7.1]
  def change
    change_table :patients, bulk: true do |t|
      t.string :decrypted_family_name
      t.string :decrypted_given_name
    end

    add_index :patients, :decrypted_family_name
    add_index :patients, :decrypted_given_name

    reversible do |dir|
      dir.up do
        # Copy existing encrypted data to new columns
        Patient.find_each do |patient|
          patient.update_columns(
            decrypted_family_name: patient.family_name,
            decrypted_given_name: patient.given_name
          )
        end
      end
    end

    # Make the new columns non-nullable after populating data
    change_table :patients, bulk: true do |t|
      t.change_null :decrypted_family_name, false
      t.change_null :decrypted_given_name, false
    end
  end
end
