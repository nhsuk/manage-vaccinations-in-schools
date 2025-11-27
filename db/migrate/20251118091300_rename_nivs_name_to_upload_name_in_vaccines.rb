# frozen_string_literal: true

class RenameNivsNameToUploadNameInVaccines < ActiveRecord::Migration[8.1]
  def up
    rename_column :vaccines, :nivs_name, :upload_name

    if index_exists?(:vaccines, :nivs_name)
      rename_index :vaccines,
                   "index_vaccines_on_nivs_name",
                   "index_vaccines_on_upload_name"
    end
  end

  def down
    rename_column :vaccines, :upload_name, :nivs_name

    if index_exists?(:vaccines, :upload_name)
      rename_index :vaccines,
                   "index_vaccines_on_upload_name",
                   "index_vaccines_on_nivs_name"
    end
  end
end
