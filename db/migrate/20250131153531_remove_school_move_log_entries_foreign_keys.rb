# frozen_string_literal: true

class RemoveSchoolMoveLogEntriesForeignKeys < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :school_move_log_entries, :patients
    remove_foreign_key :school_move_log_entries, :users
    remove_foreign_key :school_move_log_entries, :schools, to_table: :locations
  end
end
