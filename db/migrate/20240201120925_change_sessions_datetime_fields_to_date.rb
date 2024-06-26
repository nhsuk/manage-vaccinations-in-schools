# frozen_string_literal: true

class ChangeSessionsDatetimeFieldsToDate < ActiveRecord::Migration[7.1]
  def up
    change_table :sessions, bulk: true do |t|
      t.change :date, :date
      t.change :send_consent_at, :date
      t.change :send_reminders_at, :date
      t.change :close_consent_at, :date
    end
  end

  def down
    change_table :sessions, bulk: true do |t|
      t.change :date, :datetime
      t.change :send_consent_at, :datetime
      t.change :send_reminders_at, :datetime
      t.change :close_consent_at, :datetime
    end
  end
end
