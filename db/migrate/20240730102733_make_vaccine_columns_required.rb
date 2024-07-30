# frozen_string_literal: true

class MakeVaccineColumnsRequired < ActiveRecord::Migration[7.1]
  def change
    Vaccine.update_all(
      snomed_product_code: "",
      snomed_product_term: "",
      supplier: ""
    )

    change_table :vaccines, bulk: true do |t|
      t.change_null :brand, false
      t.change_null :dose, false
      t.change_null :method, false
      t.change_null :snomed_product_code, false
      t.change_null :snomed_product_term, false
      t.change_null :supplier, false
      t.change_null :type, false
    end
  end
end
