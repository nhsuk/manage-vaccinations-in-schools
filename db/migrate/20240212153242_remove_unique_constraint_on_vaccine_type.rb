class RemoveUniqueConstraintOnVaccineType < ActiveRecord::Migration[7.1]
  def change
    remove_index :vaccines, :type, unique: true
  end
end
