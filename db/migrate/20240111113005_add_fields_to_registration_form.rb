class AddFieldsToRegistrationForm < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/NotNullColumn
  def change
    change_table :registrations, bulk: true do |t|
      t.string :parent_name, null: false
      t.integer :parent_relationship, null: false
      t.string :parent_relationship_other
      t.string :parent_email, null: false
      t.string :parent_phone
    end
  end
  # rubocop:enable Rails/NotNullColumn
end
