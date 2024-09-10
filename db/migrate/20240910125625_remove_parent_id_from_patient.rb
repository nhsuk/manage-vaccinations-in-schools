# frozen_string_literal: true

class RemoveParentIdFromPatient < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :parent_id, :integer
  end
end
