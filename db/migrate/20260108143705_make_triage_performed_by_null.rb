# frozen_string_literal: true

class MakeTriagePerformedByNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :triages, :performed_by_user_id, true
  end
end
