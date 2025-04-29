class RemoveMoveToSchoolFromSchoolMoveLogEntries < ActiveRecord::Migration[8.0]
  def change
    remove_column :school_move_log_entries, :move_to_school, :boolean
  end
end
