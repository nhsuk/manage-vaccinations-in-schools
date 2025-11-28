# frozen_string_literal: true

class AddSchoolMoveLogEntryToImportantNotices < ActiveRecord::Migration[8.1]
  def change
    add_reference :important_notices, :school_move_log_entry, foreign_key: true
  end
end
