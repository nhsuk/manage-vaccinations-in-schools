# frozen_string_literal: true

class AddProgrammeToCohortImports < ActiveRecord::Migration[7.2]
  def up
    add_reference :cohort_imports, :programme, foreign_key: true

    CohortImport.all.find_each do |cohort_import|
      cohort_import.update!(programme: cohort_import.team.programmes.first)
    end

    change_column_null :cohort_imports, :programme_id, false
  end

  def down
    remove_reference :cohort_imports, :programme
  end
end
