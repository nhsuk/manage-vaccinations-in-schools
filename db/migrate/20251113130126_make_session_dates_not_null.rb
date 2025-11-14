# frozen_string_literal: true

class MakeSessionDatesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :sessions, :dates, false
  end
end
