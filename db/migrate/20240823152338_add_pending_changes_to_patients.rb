# frozen_string_literal: true

class AddPendingChangesToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :pending_changes, :jsonb, default: {}, null: false
  end
end
