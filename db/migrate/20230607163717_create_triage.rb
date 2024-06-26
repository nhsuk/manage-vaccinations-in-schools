# frozen_string_literal: true

class CreateTriage < ActiveRecord::Migration[7.0]
  def change
    create_table :triage do |t|
      t.references :campaign
      t.references :patient
      t.integer :status
      t.text :notes

      t.timestamps
    end
  end
end
