# frozen_string_literal: true

class PatientsAgedOutOfSchoolJob < ApplicationJob
  queue_as :patients

  def perform
    academic_year = AcademicYear.pending

    Patient
      .where.not(school_id: nil)
      .includes(school: :organisation)
      .find_each do |patient|
        year_group = patient.year_group(academic_year:)
        school = patient.school

        next if school.year_groups.include?(year_group)

        organisation = school.organisation
        SchoolMove.new(patient:, home_educated: false, organisation:).confirm!
      end
  end
end
