# frozen_string_literal: true

class AllowNullParentRegistrationFields < ActiveRecord::Migration[7.1]
  def up
    change_table :registrations, bulk: true do |t|
      t.change :parent_name, :string, null: true
      t.change :parent_relationship, :integer, null: true
      t.change :parent_email, :string, null: true
    end
  end

  def down
    change_table :registrations, bulk: true do |t|
      t.change :parent_name, :string, null: false
      t.change :parent_relationship, :integer, null: false
      t.change :parent_email, :string, null: false
    end
  end
end
