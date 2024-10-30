# frozen_string_literal: true

class AddDaysBeforeInvitationsToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams,
               :days_before_invitations,
               :integer,
               default: 21,
               null: false
  end
end
