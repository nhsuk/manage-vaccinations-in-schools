# frozen_string_literal: true

class DropSessionDates < ActiveRecord::Migration[8.1]
  def up
    drop_table :session_dates
  end
end
