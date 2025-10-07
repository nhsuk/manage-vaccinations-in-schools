# frozen_string_literal: true

describe API::Reporting::ResetController do
  before do
    Flipper.enable(:reporting_api)
    request.headers["Authorization"] = "Bearer #{valid_jwt}"
  end

  include ReportingAPIHelper

  describe "#create" do
    it "calls refresh! and redirects" do
      expect(ReportingAPI::PatientProgrammeStatus).to receive(:refresh!)
      get :create
      expect(response).to redirect_to("/reports")
    end
  end
end
