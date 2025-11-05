# frozen_string_literal: true

class StatusUpdaterJob < ApplicationJob
  include SingleConcurrencyConcern

  queue_as :cache

  def perform(patient: nil, session: nil)
    academic_years = [AcademicYear.current, AcademicYear.pending].uniq
    StatusUpdater.call(patient:, session:, academic_years:)
  end
end
