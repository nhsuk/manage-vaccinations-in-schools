# frozen_string_literal: true

class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :created_by_user,
                   null: false,
                   foreign_key: {
                     to_table: :users
                   }
      t.references :patient, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true

      t.text :body, null: false

      t.timestamps
    end
  end
end
