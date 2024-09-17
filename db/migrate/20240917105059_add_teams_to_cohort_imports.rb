# frozen_string_literal: true

class AddTeamsToCohortImports < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_reference :cohort_imports, :team, foreign_key: true, null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
