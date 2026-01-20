# frozen_string_literal: true

class AddLocationToPatientProgrammeStatuses < ActiveRecord::Migration[8.1]
  def change
    add_reference :patient_programme_statuses, :location
  end
end
