# frozen_string_literal: true

desc "Migrate patients who were moved out of cohorts to ensure they're archived."
task archive_moved_out_of_cohort_patients: :environment do
  Team.find_each do |team|
    user = OpenStruct.new(selected_team: team)

    patients_in_cohort = team.patients
    patients_associated_with_team =
      PatientPolicy::Scope.new(user, Patient).resolve

    patients_not_in_cohort = patients_associated_with_team - patients_in_cohort

    archive_reasons =
      patients_not_in_cohort.map do |patient|
        ArchiveReason.new(
          patient:,
          team:,
          type: "other",
          other_details: "Unknown: before reasons added"
        )
      end

    ArchiveReason.import!(archive_reasons, on_duplicate_key_ignore: true)
  end
end
