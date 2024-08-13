# frozen_string_literal: true

class AddTypeToLocations < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :locations, :type, :integer, null: false, default: 0
    change_column_default :locations, :type, from: 0, to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
