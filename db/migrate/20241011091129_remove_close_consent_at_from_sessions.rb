# frozen_string_literal: true

class RemoveCloseConsentAtFromSessions < ActiveRecord::Migration[7.2]
  def change
    remove_column :sessions, :close_consent_at, :datetime
  end
end
