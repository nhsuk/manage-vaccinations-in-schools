# frozen_string_literal: true

class AddDelegationToSessions < ActiveRecord::Migration[8.0]
  def change
    change_table :sessions, bulk: true do |t|
      t.boolean :psd_enabled, default: false, null: false
      t.boolean :national_protocol_enabled, default: false, null: false
    end
  end
end
