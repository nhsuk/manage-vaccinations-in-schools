# frozen_string_literal: true

class CopyDecryptedNamesAndRemoveEncryptedColumns < ActiveRecord::Migration[7.1]
  def up
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    Patient.find_each do |patient|
      patient.update_columns(
        family_name: patient.decrypted_family_name,
        given_name: patient.decrypted_given_name
      )
    end

    # Create GiST indexes for trigram searching
    add_index :patients,
              "family_name gin_trgm_ops",
              using: :gin,
              name: "index_patients_on_family_name_trigram"
    add_index :patients,
              "given_name gin_trgm_ops",
              using: :gin,
              name: "index_patients_on_given_name_trigram"

    # Create composite indexes for sorting and exact matches
    add_index :patients,
              %i[family_name given_name],
              name: "index_patients_on_names_family_first"
    add_index :patients,
              %i[given_name family_name],
              name: "index_patients_on_names_given_first"

    change_table :patients, bulk: true do |t|
      t.remove :decrypted_family_name
      t.remove :decrypted_given_name
      t.remove :original_family_name
      t.remove :original_given_name
    end
  end

  def down
    change_table :patients, bulk: true do |t|
      t.string :decrypted_family_name
      t.string :decrypted_given_name

      t.string :original_family_name
      t.string :original_given_name
    end

    add_index :patients, :decrypted_family_name
    add_index :patients, :decrypted_given_name

    remove_index :patients, name: "index_patients_on_family_name_trigram"
    remove_index :patients, name: "index_patients_on_given_name_trigram"
    remove_index :patients, name: "index_patients_on_names_family_first"
    remove_index :patients, name: "index_patients_on_names_given_first"

    Patient.find_each do |patient|
      patient.update_columns(
        decrypted_family_name: patient.family_name,
        decrypted_given_name: patient.given_name,
        original_family_name: patient.family_name,
        original_given_name: patient.given_name
      )
    end

    change_table :patients, bulk: true do |t|
      t.change_null :decrypted_family_name, false
      t.change_null :decrypted_given_name, false
      t.change_null :original_family_name, false
      t.change_null :original_given_name, false
    end
  end
end
