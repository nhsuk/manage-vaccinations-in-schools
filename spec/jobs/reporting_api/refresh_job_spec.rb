# frozen_string_literal: true

describe ReportingAPI::RefreshJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    before { Flipper.enable(:reporting_api) }

    it "refreshes the reporting API materialized view" do
      expect(ReportingAPI::PatientProgrammeStatus).to receive(:refresh!)
      perform
    end
  end
end
