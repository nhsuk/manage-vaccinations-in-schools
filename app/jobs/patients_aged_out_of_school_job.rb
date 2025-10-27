# frozen_string_literal: true

class PatientsAgedOutOfSchoolJob
  include Sidekiq::Job

  sidekiq_options queue: :patients

  def perform(school_id)
    return if school_id.nil?

    academic_year = AcademicYear.pending

    school =
      Location.school.includes(:location_year_groups, :team).find(school_id)

    # Year groups not yet set up for the next academic year.
    if school.location_year_groups.none? { it.academic_year == academic_year }
      return
    end

    team = school.team

    Patient
      .where(school_id:)
      .find_each do |patient|
        year_group = patient.year_group(academic_year:)

        school_has_year_group =
          school.location_year_groups.any? do
            it.academic_year == academic_year && it.value == year_group
          end

        next if school_has_year_group

        SchoolMove.new(
          patient:,
          home_educated: false,
          team:,
          academic_year:
        ).confirm!
      end
  end
end
