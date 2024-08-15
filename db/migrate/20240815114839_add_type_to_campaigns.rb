# frozen_string_literal: true

class AddTypeToCampaigns < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :campaigns, :type, :string, null: false, default: "hpv"
    change_column_default :campaigns, :type, from: "hpv", to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
