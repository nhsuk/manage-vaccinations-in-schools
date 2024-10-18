# frozen_string_literal: true

class AddRestrictedAtToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :restricted_at, :datetime
  end
end
