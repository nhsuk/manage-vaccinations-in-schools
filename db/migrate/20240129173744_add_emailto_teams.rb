# frozen_string_literal: true

class AddEmailtoTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :email, :string
  end
end
