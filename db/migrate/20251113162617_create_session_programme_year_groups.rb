# frozen_string_literal: true

class CreateSessionProgrammeYearGroups < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :session_programme_year_groups,
                 primary_key: %i[session_id programme_type year_group] do |t|
      t.references :session, foreign_key: { on_delete: :cascade }, null: false
      t.enum :programme_type, enum_type: :programme_type, null: false
      t.integer :year_group, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
