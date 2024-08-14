# frozen_string_literal: true

class AddDPSExports < ActiveRecord::Migration[7.1]
  def change
    create_table :dps_exports do |t|
      t.string :message_id
      t.string :status, null: false, default: "pending"
      t.string :filename
      t.timestamp :sent_at
      t.references :campaign, null: false, foreign_key: true
      t.timestamps
    end
  end
end
