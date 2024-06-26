# frozen_string_literal: true

class RenameConsentChildCommonName < ActiveRecord::Migration[7.1]
  def change
    rename_column :consents, :childs_common_name, :common_name
  end
end
