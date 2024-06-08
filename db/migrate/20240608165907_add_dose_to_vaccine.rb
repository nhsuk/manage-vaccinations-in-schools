class AddDoseToVaccine < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccines, :dose, :decimal
  end
end
