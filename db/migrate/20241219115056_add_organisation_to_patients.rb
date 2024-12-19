# frozen_string_literal: true

class AddOrganisationToPatients < ActiveRecord::Migration[8.0]
  def up
    add_reference :patients, :organisation, foreign_key: true
    Patient
      .eager_load(:cohort)
      .find_each do |patient|
        patient.update_column(:organisation_id, patient.cohort&.organisation)
      end
  end

  def down
    remove_reference :patients, :organisation
  end
end
