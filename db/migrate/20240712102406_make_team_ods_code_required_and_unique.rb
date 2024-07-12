# frozen_string_literal: true

class MakeTeamOdsCodeRequiredAndUnique < ActiveRecord::Migration[7.1]
  def change
    change_column_null :teams, :ods_code, false
    add_index :teams, :ods_code, unique: true
  end
end
