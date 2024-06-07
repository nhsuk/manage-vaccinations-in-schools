class CreateParents < ActiveRecord::Migration[7.1]
  def change
    create_table :parents do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.integer :relationship
      t.string :relationship_other
      t.integer :contact_method
      t.text :contact_method_other

      t.timestamps
    end
  end
end
