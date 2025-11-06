# frozen_string_literal: true

describe API::Testing::ReportingRefreshController do
  describe "#create" do
    it "performs the refresh job and responds with accepted status" do
      expect(ReportingAPI::RefreshJob).to receive(:perform_later)
      get :create
      expect(response).to have_http_status(:accepted)
    end
  end
end
