# frozen_string_literal: true

class RemoveUniqueIndexFromSessions < ActiveRecord::Migration[8.0]
  def up
    remove_index :sessions,
                 column: %i[organisation_id location_id academic_year]

    add_index :sessions, %i[organisation_id location_id]
    add_index :sessions, :location_id
  end

  def down
    remove_index :sessions, column: :location_id
    remove_index :sessions, column: %i[organisation_id location_id]
    add_index :sessions,
              %i[organisation_id location_id academic_year],
              unique: true
  end
end
