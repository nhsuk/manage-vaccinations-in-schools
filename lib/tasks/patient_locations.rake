# frozen_string_literal: true

namespace :patient_locations do
  desc "Remove stale patient locations from previous schools"
  task cleanup_post_school_move: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") == "true"

    puts "Starting cleanup of stale patient locations from previous schools"
    puts "DRY RUN MODE - No records will be destroyed" if dry_run

    patients_with_multiple_locations =
      Patient.where(
        id:
          PatientLocation
            .where.not(location_id: Location.clinic)
            .where(academic_year: AcademicYear.current)
            .group(:patient_id)
            .having("COUNT(*) > 1")
            .select(:patient_id)
      )

    total = patients_with_multiple_locations.count
    puts "Found #{total} patients with multiple locations"

    progress_bar =
      # rubocop:disable Rails/SaveBang
      ProgressBar.create(
        total:,
        format: "%a %b\u{15E7}%i %p%% %t",
        progress_mark: " ",
        remainder_mark: "\u{FF65}"
      )
    # rubocop:enable Rails/SaveBang

    safe_to_destroy_count = 0

    patients_with_multiple_locations.find_each do |patient|
      patient_locations_to_destroy =
        patient
          .patient_locations
          .where(academic_year: AcademicYear.current)
          .where.not(location_id: patient.school_id)

      safe_to_destroy_count += patient_locations_to_destroy.count

      patient_locations_to_destroy.destroy_all unless dry_run

      progress_bar.increment
    end

    puts(
      if dry_run
        "Would destroy: #{safe_to_destroy_count}"
      else
        "Safely destroyed: #{safe_to_destroy_count}"
      end
    )
  end
end
