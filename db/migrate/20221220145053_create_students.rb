# frozen_string_literal: true

class CreateStudents < ActiveRecord::Migration[7.0]
  def change
    create_table :students do |t|
      t.string :name
      t.date :dob
      t.decimal :nhs_number

      t.timestamps
    end
  end
end
