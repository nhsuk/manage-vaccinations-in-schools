# frozen_string_literal: true

class PatientsAgedOutOfSchoolJob < ApplicationJob
  queue_as :patients

  def perform
    academic_year = AcademicYear.pending

    Patient
      .where.not(school_id: nil)
      .includes(school: :team)
      .find_each do |patient|
        year_group = patient.year_group(academic_year:)
        school = patient.school

        # Year groups not yet set up for the next academic year.
        next if school.location_year_groups.where(academic_year:).empty?

        # Year group is valid for the school.
        if school.location_year_groups.exists?(
             academic_year:,
             value: year_group
           )
          next
        end

        team = school.team

        SchoolMove.new(
          patient:,
          home_educated: false,
          team:,
          academic_year:
        ).confirm!
      end
  end
end
