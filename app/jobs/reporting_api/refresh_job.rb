# frozen_string_literal: true

class ReportingAPI::RefreshJob < ApplicationJob
  def perform
    ReportingAPI::PatientProgrammeStatus.refresh!
    ReportingAPI::Total.refresh!
  end
end
