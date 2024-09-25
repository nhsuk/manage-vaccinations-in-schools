# frozen_string_literal: true

class RemoveTimeOfDayFromSessions < ActiveRecord::Migration[7.2]
  def change
    remove_column :sessions, :time_of_day, :integer
  end
end
