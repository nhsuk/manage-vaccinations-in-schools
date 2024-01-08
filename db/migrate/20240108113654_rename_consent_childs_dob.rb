class RenameConsentChildsDob < ActiveRecord::Migration[7.1]
  def change
    rename_column :consents, :childs_dob, :date_of_birth
  end
end
