# frozen_string_literal: true

class AddLocalAuthority < ActiveRecord::Migration[8.0]
  def change
    create_table :local_authorities, id: false, primary_key: :mhclg_code do |t|
      t.string :mhclg_code, null: false
      t.string :gss_code
      t.integer :gias_code
      t.string :official_name, null: false
      t.string :short_name, null: false
      t.string :gov_uk_slug
      t.string :nation, null: false
      t.string :region
      t.date :end_date
      t.timestamps

      t.index :mhclg_code, unique: true
      t.index :gss_code, unique: true
      t.index :gias_code, unique: true
      t.index :short_name
      t.index %i[nation short_name]
      t.index :created_at
    end
  end
end
