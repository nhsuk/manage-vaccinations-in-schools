# frozen_string_literal: true

class RenameImmunisationImportUserToUploadedByUser < ActiveRecord::Migration[
  7.2
]
  def change
    rename_column :immunisation_imports, :user_id, :uploaded_by_user_id
  end
end
