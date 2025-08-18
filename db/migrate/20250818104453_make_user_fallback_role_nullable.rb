# frozen_string_literal: true

class MakeUserFallbackRoleNullable < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.change_null :fallback_role, true
      t.change_default :fallback_role, from: 0, to: nil
    end
  end
end
