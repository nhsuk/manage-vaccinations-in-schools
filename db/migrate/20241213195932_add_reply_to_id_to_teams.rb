# frozen_string_literal: true

class AddReplyToIdToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :reply_to_id, :uuid
  end
end
