# frozen_string_literal: true

class ReviewClassImportSchoolMoveJob < ApplicationJob
  queue_as :imports

  def perform(import_id)
    import = ClassImport.find(import_id)

    if import.in_review? || import.low_pds_match_rate? ||
         import.changesets.any?(&:calculating_review?)
      return
    end

    patients_in_import =
      import.changesets.ready_for_review.map(&:patient) + import.patients

    patients_in_future_review = import.changesets.needs_re_review.map(&:patient)

    existing_patients =
      Patient.where(birth_academic_year: birth_academic_years).where(
        PatientLocation
          .joins(:location)
          .where("patient_id = patients.id")
          .where(academic_year:, location:)
          .arel
          .exists
      )

    patients_with_school_moves =
      existing_patients.select { it.school_moves.where(school_id: nil).exists? }

    unknown_patients =
      existing_patients - patients_in_import - patients_in_future_review -
        patients_with_school_moves

    unknown_patients.map do |patient|
      PatientChangeset.create!(
        import:,
        row_number: nil,
        patient_id: patient.id,
        status: :ready_for_review,
        record_type: :not_in_file,
        data: {
          upload: {
            child: {
              given_name: patient.given_name,
              family_name: patient.family_name,
              date_of_birth: patient.date_of_birth,
              address_postcode: patient.address_postcode,
              birth_academic_year: patient.birth_academic_year
            }
          },
          review: {
            school_move: {
              school_id: nil,
              home_educated: false
            }
          }
        }
      )
    end

    import.in_review!
  end
end
