# frozen_string_literal: true

class AddTimeOfDayToSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :sessions, :time_of_day, :integer
  end
end
