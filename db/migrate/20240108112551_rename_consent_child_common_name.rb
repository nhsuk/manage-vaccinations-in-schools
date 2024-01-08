class RenameConsentChildCommonName < ActiveRecord::Migration[7.1]
  def change
    rename_column :consents, :common_name, :common_name
  end
end
