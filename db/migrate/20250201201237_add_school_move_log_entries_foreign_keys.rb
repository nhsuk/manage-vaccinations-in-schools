# frozen_string_literal: true

class AddSchoolMoveLogEntriesForeignKeys < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :school_move_log_entries, :patients
    add_foreign_key :school_move_log_entries, :users
    add_foreign_key :school_move_log_entries, :locations, column: :school_id
  end
end
