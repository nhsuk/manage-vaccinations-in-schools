# frozen_string_literal: true

class MakeBatchTeamNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :batches, :team_id, true
  end
end
