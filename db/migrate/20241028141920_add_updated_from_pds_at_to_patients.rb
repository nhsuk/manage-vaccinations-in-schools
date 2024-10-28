# frozen_string_literal: true

class AddUpdatedFromPDSAtToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :updated_from_pds_at, :datetime
  end
end
