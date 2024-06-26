# frozen_string_literal: true

class AddOdsCodeToTeam < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :ods_code, :string
  end
end
