# frozen_string_literal: true

class AddAcademicYearToCampaigns < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :campaigns, :academic_year, :integer, null: false, default: 2024
    change_column_default :campaigns, :academic_year, from: 2024, to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
