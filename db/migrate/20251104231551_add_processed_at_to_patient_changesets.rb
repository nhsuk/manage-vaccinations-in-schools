# frozen_string_literal: true

class AddProcessedAtToPatientChangesets < ActiveRecord::Migration[8.1]
  def change
    add_column :patient_changesets, :processed_at, :datetime
  end
end
