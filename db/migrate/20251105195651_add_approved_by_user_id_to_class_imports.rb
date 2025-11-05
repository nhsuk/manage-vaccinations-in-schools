# frozen_string_literal: true

class AddApprovedByUserIdToClassImports < ActiveRecord::Migration[8.1]
  def change
    change_table :class_imports, bulk: true do |t|
      t.bigint :reviewed_by_user_ids, array: true, default: [], null: false
      t.datetime :reviewed_at, array: true, default: [], null: false
    end
  end
end
