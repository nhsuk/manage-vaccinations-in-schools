# frozen_string_literal: true

class RemoveProgrammeFromCohortImports < ActiveRecord::Migration[8.0]
  def change
    remove_reference :cohort_imports, :programme, foreign_key: true, null: false
  end
end
