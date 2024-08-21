# frozen_string_literal: true

class RenameVaccinationRecordUserToPerformedBy < ActiveRecord::Migration[7.1]
  def change
    rename_column :vaccination_records, :user_id, :performed_by_user_id
  end
end
