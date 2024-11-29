# frozen_string_literal: true

class ConsolidatePatientSchoolHomeEducated < ActiveRecord::Migration[7.2]
  def change
    # school present and home_educated_nil => known school
    # school nil and home_educated true => home schooled
    # school nil and home_educated false => unknown school

    Patient.where.not(school_id: nil).update_all(home_educated: nil)
    Patient.where(school_id: nil, home_educated: nil).update_all(
      home_educated: false
    )
    Patient.where(home_educated: true).update_all(school_id: nil)
    Patient.where(home_educated: false).update_all(school_id: nil)

    if (patients = Patient.all.select(&:invalid?)).present?
      errors = patients.sample(5).flat_map { _1.errors.full_messages }
      raise "Patients are not all valid. Aborting to rollback transaction. " \
              "Sample of errors: #{errors.to_sentence}"
    end
  end
end
