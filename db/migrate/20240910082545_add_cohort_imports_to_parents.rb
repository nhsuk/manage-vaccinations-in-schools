# frozen_string_literal: true

class AddCohortImportsToParents < ActiveRecord::Migration[7.2]
  def change
    create_join_table :cohort_imports,
                      :parents,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[cohort_import_id parent_id], unique: true
    end
  end
end
