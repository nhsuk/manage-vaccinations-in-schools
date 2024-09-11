# frozen_string_literal: true

class CreateParentRelationships < ActiveRecord::Migration[7.2]
  def change
    create_table :parent_relationships do |t|
      t.references :parent, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true

      t.string :type, null: false
      t.string :other_name

      t.timestamps

      t.index %i[parent_id patient_id], unique: true
    end

    create_join_table :cohort_imports,
                      :parent_relationships,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[cohort_import_id parent_relationship_id], unique: true
    end
  end
end
