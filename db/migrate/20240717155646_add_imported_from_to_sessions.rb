# frozen_string_literal: true

class AddImportedFromToSessions < ActiveRecord::Migration[7.1]
  def change
    add_reference :sessions,
                  :imported_from,
                  foreign_key: {
                    to_table: :immunisation_imports
                  }
  end
end
