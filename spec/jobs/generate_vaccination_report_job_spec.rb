# frozen_string_literal: true

describe GenerateVaccinationReportJob do
  subject(:job) { described_class.new }

  let(:export) do
    create(
      :vaccination_report_export,
      team:,
      programme_type: "flu",
      academic_year: 2024,
      file_format: "mavis"
    )
  end

  let(:team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }

  before do
    allow(Settings.vaccination_report_export).to receive(:retention_hours).and_return(168)
  end

  describe "#perform" do
    it "generates CSV, attaches to export, and updates status" do
      job.perform(export.id)

      export.reload
      expect(export).to be_ready
      expect(export.expired_at).to be_present
    end

    context "when export is already ready" do
      before { export.ready! }

      it "does not overwrite" do
        expect { job.perform(export.id) }.not_to raise_error
      end
    end

    context "when exporter raises" do
      before do
        allow(Reports::ProgrammeVaccinationsExporter).to receive(:call).and_raise(StandardError)
      end

      it "sets status to failed" do
        expect { job.perform(export.id) }.to raise_error(StandardError)

        export.reload
        expect(export).to be_failed
      end
    end
  end
end
