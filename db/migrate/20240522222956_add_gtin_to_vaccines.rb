class AddGtinToVaccines < ActiveRecord::Migration[7.1]
  def change
    change_table :vaccines do |t|
      t.text :gtin
    end
  end
end
