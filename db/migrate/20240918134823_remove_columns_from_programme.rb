# frozen_string_literal: true

class RemoveColumnsFromProgramme < ActiveRecord::Migration[7.2]
  def change
    change_table :programmes, bulk: true do |t|
      t.remove :academic_year, type: :integer
      t.remove :end_date, type: :date
      t.remove :name, type: :string
      t.remove :start_date, type: :date
      t.change_null :type, false
      t.index %i[team_id type], unique: true
    end
  end
end
