# frozen_string_literal: true

class AddIndexOnSessionTeamAndAcademicYear < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :sessions, %i[team_id academic_year], algorithm: :concurrently
  end
end
