# frozen_string_literal: true

class RemoveDraftProgrammes < ActiveRecord::Migration[7.2]
  def up
    Programme.where(active: false).delete_all
    remove_column :programmes, :active
  end

  def down
    add_column :programmes, :active, :boolean, default: false, null: false
  end
end
