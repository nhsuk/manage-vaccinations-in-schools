# frozen_string_literal: true

class CreateParentsPatientsJoinTable < ActiveRecord::Migration[7.2]
  def change
    create_join_table :parents,
                      :patients,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[parent_id patient_id]
      t.index %i[patient_id parent_id]
    end
  end
end
