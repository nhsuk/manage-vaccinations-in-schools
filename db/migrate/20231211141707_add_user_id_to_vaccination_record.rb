# frozen_string_literal: true

class AddUserIdToVaccinationRecord < ActiveRecord::Migration[7.1]
  def change
    add_reference :vaccination_records, :user, foreign_key: { to_table: :users }
  end
end
