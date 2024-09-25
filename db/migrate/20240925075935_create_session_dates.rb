# frozen_string_literal: true

class CreateSessionDates < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :session_dates do |t|
      t.references :session, foreign_key: true, null: false
      t.date :value, null: false
      t.index %i[session_id value], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
