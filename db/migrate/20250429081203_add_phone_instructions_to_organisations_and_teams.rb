# frozen_string_literal: true

class AddPhoneInstructionsToOrganisationsAndTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :phone_instructions, :string
    add_column :teams, :phone_instructions, :string
  end
end
