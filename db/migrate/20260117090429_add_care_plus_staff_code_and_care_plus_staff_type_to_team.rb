# frozen_string_literal: true

class AddCarePlusStaffCodeAndCarePlusStaffTypeToTeam < ActiveRecord::Migration[
  8.1
]
  def change
    change_table :teams do |t|
      t.string :careplus_staff_code, :careplus_staff_type
    end
  end
end
