class AddSiteToVaccinationRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :vaccination_records, :site, :integer
  end
end
