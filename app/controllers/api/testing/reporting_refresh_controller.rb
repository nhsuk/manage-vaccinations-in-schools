# frozen_string_literal: true

class API::Testing::ReportingRefreshController < API::Testing::BaseController
  def create
    ReportingAPI::PatientProgrammeStatus.refresh!
    redirect_to "/reports"
  end
end
