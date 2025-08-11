# frozen_string_literal: true

class AddOneTimeTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :reporting_api_one_time_tokens, id: false do |t|
      t.references :user,
                   foreign_key: true,
                   null: false,
                   index: {
                     unique: true
                   }
      t.string :token, null: false, primary_key: true
      t.jsonb :cis2_info, null: false, default: {}
      t.timestamps

      t.index :token, unique: true
      t.index :created_at
    end
  end
end
