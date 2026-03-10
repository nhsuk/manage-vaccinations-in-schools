# frozen_string_literal: true

describe CleanupVaccinationReportExportsJob do
  subject(:job) { described_class.new }

  let(:team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }

  before do
    allow(Settings.vaccination_report_export).to receive(:retention_hours).and_return(168)
  end

  describe "#perform" do
    context "when there are exports older than retention period" do
      let!(:old_export) do
        export = create(:vaccination_report_export, team:, programme_type: "flu")
        export.update_column(:created_at, 200.hours.ago)
        export.file.attach(
          io: StringIO.new("csv,data"),
          filename: "test.csv",
          content_type: "text/csv"
        )
        export.ready!
        export
      end

      it "purges the file and marks the export as expired" do
        job.perform

        old_export.reload
        expect(old_export).to be_expired
        expect(old_export.file).not_to be_attached
      end
    end

    context "when there are recent exports within retention period" do
      let!(:recent_export) do
        create(:vaccination_report_export, team:, programme_type: "flu")
      end

      it "does not expire recent exports" do
        job.perform

        recent_export.reload
        expect(recent_export).to be_pending
      end
    end

    context "when an export is already expired" do
      let!(:already_expired) do
        export = create(:vaccination_report_export, team:, programme_type: "flu")
        export.update_column(:created_at, 200.hours.ago)
        export.expired!
        export
      end

      it "does not raise" do
        expect { job.perform }.not_to raise_error
      end
    end
  end
end
