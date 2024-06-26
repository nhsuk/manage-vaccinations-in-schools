# frozen_string_literal: true

class AddPhoneToTeam < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :phone, :string
  end
end
