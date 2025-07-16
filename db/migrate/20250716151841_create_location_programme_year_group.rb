# frozen_string_literal: true

class CreateLocationProgrammeYearGroup < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :location_programme_year_groups do |t|
      t.references :location, null: false, foreign_key: { on_delete: :cascade }
      t.references :programme, null: false, foreign_key: { on_delete: :cascade }
      t.integer :year_group, null: false
      t.index %i[location_id programme_id year_group], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
