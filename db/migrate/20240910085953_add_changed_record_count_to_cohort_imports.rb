# frozen_string_literal: true

class AddChangedRecordCountToCohortImports < ActiveRecord::Migration[7.2]
  def change
    add_column :cohort_imports, :changed_record_count, :integer
  end
end
