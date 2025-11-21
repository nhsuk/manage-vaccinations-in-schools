# frozen_string_literal: true

class RemoveProgrammeTypesFromSessions < ActiveRecord::Migration[8.1]
  def change
    remove_column :sessions,
                  :programme_types,
                  :enum,
                  array: true,
                  enum_type: :programme_type
  end
end
