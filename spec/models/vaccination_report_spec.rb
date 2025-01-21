# frozen_string_literal: true

describe VaccinationReport do
  describe "file_formats" do
    subject { described_class.file_formats(programme) }

    context "when hpv and feature is disabled" do
      before { Flipper.disable(:systm_one_exporter) }

      let(:programme) { create(:programme, :hpv) }

      it { should eq(%w[careplus mavis]) }
    end

    context "when hpv and feature is enabled" do
      before { Flipper.enable(:systm_one_exporter) }

      let(:programme) { create(:programme, :hpv) }

      it { should eq(%w[careplus mavis systm_one]) }
    end

    context "when menacwy and feature is enabled" do
      before { Flipper.enable(:systm_one_exporter) }

      let(:programme) { create(:programme, :menacwy) }

      it { should eq(%w[careplus mavis]) }
    end
  end
end
