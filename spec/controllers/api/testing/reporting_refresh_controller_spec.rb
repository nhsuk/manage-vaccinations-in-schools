# frozen_string_literal: true

describe API::Testing::ReportingRefreshController do
  describe "#create" do
    it "calls refresh! and redirects" do
      expect(ReportingAPI::PatientProgrammeStatus).to receive(:refresh!)
      get :create
      expect(response).to redirect_to("/reports")
    end
  end
end
