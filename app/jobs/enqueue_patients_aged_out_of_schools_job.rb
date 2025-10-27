# frozen_string_literal: true

class EnqueuePatientsAgedOutOfSchoolsJob < ApplicationJob
  queue_as :patients

  def perform
    ids = Location.school.where.not(subteam_id: nil).pluck(:id)
    PatientsAgedOutOfSchoolJob.perform_bulk(ids.zip)
  end
end
