# frozen_string_literal: true

class RenameConsentFormInvalidatedAtToArchivedAt < ActiveRecord::Migration[8.0]
  def change
    rename_column :consent_forms, :invalidated_at, :archived_at
  end
end
