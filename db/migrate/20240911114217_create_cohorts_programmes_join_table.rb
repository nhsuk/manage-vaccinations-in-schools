# frozen_string_literal: true

class CreateCohortsProgrammesJoinTable < ActiveRecord::Migration[7.2]
  def change
    create_join_table :cohorts, :programmes do |t|
      t.index :cohort_id
      t.index :programme_id
    end
  end
end
