# frozen_string_literal: true

class CreateCampaigns < ActiveRecord::Migration[7.0]
  def change
    create_table :campaigns do |t|
      t.text :title
      t.datetime :date
      t.text :location_type
      t.integer :location_id
      t.integer :type

      t.timestamps
    end
  end
end
