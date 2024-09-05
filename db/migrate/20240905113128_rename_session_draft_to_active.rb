# frozen_string_literal: true

class RenameSessionDraftToActive < ActiveRecord::Migration[7.2]
  def up
    change_table :sessions, bulk: true do |t|
      t.rename :draft, :active
      t.change_null :active, false
    end

    Session.update_all("active = NOT active")
  end

  def down
    Session.update_all("active = NOT active")

    change_table :sessions, bulk: true do |t|
      t.rename :active, :draft
      t.change_null :draft, true
    end
  end
end
