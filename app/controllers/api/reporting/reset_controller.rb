# frozen_string_literal: true

class API::Reporting::ResetController < API::Reporting::BaseController
  def create
    ReportingAPI::PatientProgrammeStatus.refresh!
    redirect_to "/reports"
  end
end
