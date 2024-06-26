# frozen_string_literal: true

class AddReplyToIdToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :reply_to_id, :string
  end
end
