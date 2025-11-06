# frozen_string_literal: true

class API::Testing::ReportingRefreshController < API::Testing::BaseController
  def create
    ReportingAPI::RefreshJob.perform_later
    render status: :accepted
  end
end
