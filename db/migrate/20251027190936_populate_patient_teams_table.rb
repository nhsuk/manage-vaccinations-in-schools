# frozen_string_literal: true

class PopulatePatientTeamsTable < ActiveRecord::Migration[8.0]
  def change
    [PatientLocation, SchoolMove, ArchiveReason, VaccinationRecord].each do
      it.all.insert_patient_teams_relationships
    end
  end
end
