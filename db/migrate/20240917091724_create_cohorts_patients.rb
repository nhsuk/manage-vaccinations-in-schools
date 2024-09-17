# frozen_string_literal: true

class CreateCohortsPatients < ActiveRecord::Migration[7.2]
  def change
    create_join_table :cohorts,
                      :patients,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[cohort_id patient_id], unique: true
    end
  end
end
