# frozen_string_literal: true

class CreateCohorts < ActiveRecord::Migration[7.2]
  def change
    create_table :cohorts do |t|
      t.date :birth_date_from
      t.date :birth_date_to

      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
