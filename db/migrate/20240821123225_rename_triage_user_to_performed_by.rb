# frozen_string_literal: true

class RenameTriageUserToPerformedBy < ActiveRecord::Migration[7.1]
  def change
    rename_column :triage, :user_id, :performed_by_user_id
  end
end
