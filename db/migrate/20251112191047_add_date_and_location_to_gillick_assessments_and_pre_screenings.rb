# frozen_string_literal: true

class AddDateAndLocationToGillickAssessmentsAndPreScreenings < ActiveRecord::Migration[
  8.1
]
  def change
    change_table :gillick_assessments, bulk: true do |t|
      t.references :location, foreign_key: true
      t.date :date
    end

    change_table :pre_screenings, bulk: true do |t|
      t.references :location, foreign_key: true
      t.date :date
    end
  end
end
