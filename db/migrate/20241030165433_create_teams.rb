# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[7.2]
  def change
    create_table :teams do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.timestamps
      t.index %i[organisation_id name], unique: true
    end
  end
end
