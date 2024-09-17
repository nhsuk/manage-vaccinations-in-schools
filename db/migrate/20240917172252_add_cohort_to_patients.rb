# frozen_string_literal: true

class AddCohortToPatients < ActiveRecord::Migration[7.2]
  def up
    add_reference :patients, :cohort, foreign_key: true

    team = Team.first

    Patient.all.find_each do |patient|
      reception_starting_year =
        patient.date_of_birth.year + (patient.date_of_birth.month >= 9 ? 5 : 4)

      cohort = Cohort.find_or_create_by!(team:, reception_starting_year:)

      patient.update!(cohort_id: cohort.id)
    end

    change_column_null :patients, :cohort_id, false

    drop_join_table :cohorts, :patients
  end

  def down
    remove_reference :patients, :cohort

    create_join_table :cohorts,
                      :patients,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[cohort_id patient_id], unique: true
    end
  end
end
