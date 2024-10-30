# frozen_string_literal: true

class AddSendInvitationsAtToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :send_invitations_at, :date
  end
end
