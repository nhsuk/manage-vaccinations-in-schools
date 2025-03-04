# frozen_string_literal: true

describe VaccinationReport do
  describe "file_formats" do
    it "returns the default file formats" do
      expect(described_class.file_formats).to eq(%w[careplus mavis])
    end

    context "when systm_one exporter is enabled" do
      before { Flipper.enable(:systm_one_exporter) }

      it "returns the systm_one file format" do
        expect(described_class.file_formats).to eq(%w[careplus mavis systm_one])
      end
    end
  end
end
