# frozen_string_literal: true

class AddSuppliedByUserToVaccinationRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :vaccination_records,
                  :supplied_by_user,
                  foreign_key: {
                    to_table: :users
                  }
  end
end
