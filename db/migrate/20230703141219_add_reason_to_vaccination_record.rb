# frozen_string_literal: true

class AddReasonToVaccinationRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :vaccination_records, :reason, :integer
  end
end
