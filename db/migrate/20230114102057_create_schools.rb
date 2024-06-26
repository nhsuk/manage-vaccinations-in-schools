# frozen_string_literal: true

class CreateSchools < ActiveRecord::Migration[7.0]
  def change
    create_table :schools do |t|
      t.decimal :urn
      t.text :name
      t.text :address
      t.text :locality
      t.text :town
      t.text :county
      t.text :postcode
      t.decimal :minimum_age
      t.decimal :maximum_age
      t.text :url
      t.integer :phase
      t.text :type
      t.text :detailed_type

      t.timestamps
    end
  end
end
