# frozen_string_literal: true

class ReportingAPI::RefreshJob < ApplicationJob
  def perform
    return unless Flipper.enabled?(:reporting_api)

    ReportingAPI::PatientProgrammeStatus.refresh!
    ReportingAPI::Total.refresh!
  end
end
