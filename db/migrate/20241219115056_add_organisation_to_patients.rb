# frozen_string_literal: true

class AddOrganisationToPatients < ActiveRecord::Migration[8.0]
  def up
    add_reference :patients, :organisation, foreign_key: true

    Patient
      .where.not(cohort_id: nil)
      .find_each do |patient|
        cohort = Cohort.find(patient.cohort_id)
        patient.update_column(:organisation_id, cohort.organisation_id)
      end
  end

  def down
    remove_reference :patients, :organisation
  end
end
