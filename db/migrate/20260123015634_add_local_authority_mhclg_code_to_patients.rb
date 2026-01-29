# frozen_string_literal: true

class AddLocalAuthorityMhclgCodeToPatients < ActiveRecord::Migration[8.1]
  def change
    add_column :patients, :local_authority_mhclg_code, :string
    add_index :patients, :local_authority_mhclg_code
  end
end
