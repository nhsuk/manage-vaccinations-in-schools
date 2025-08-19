class AddSourceToVaccinationRecord < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records, :source, :integer
  end
end
