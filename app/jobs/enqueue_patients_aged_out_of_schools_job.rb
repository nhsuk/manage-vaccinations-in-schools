# frozen_string_literal: true

class EnqueuePatientsAgedOutOfSchoolsJob < ApplicationJob
  queue_as :patients

  def perform
    academic_year = AcademicYear.pending
    ids = Location.school.with_team(academic_year:).pluck(:id)
    PatientsAgedOutOfSchoolJob.perform_bulk(ids.zip)
  end
end
