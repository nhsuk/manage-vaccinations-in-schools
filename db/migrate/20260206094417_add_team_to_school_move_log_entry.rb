# frozen_string_literal: true

class AddTeamToSchoolMoveLogEntry < ActiveRecord::Migration[8.1]
  def change
    add_reference :school_move_log_entries, :team, null: true, foreign_key: true
  end
end
