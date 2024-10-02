# frozen_string_literal: true

describe ProcessImportJob do
  let(:programme) { create(:programme) }
  let(:cohort_import) { create(:cohort_import, programme:) }
  let(:immunisation_import) { create(:immunisation_import, programme:) }

  describe "#perform" do
    it "assigns the programme to the cohort import and processes it" do
      allow(cohort_import).to receive(:parse_rows!)
      allow(cohort_import).to receive(:process!)

      expect(cohort_import).to receive(:programme=).with(programme)
      expect(cohort_import).to receive(:parse_rows!)
      expect(cohort_import).to receive(:process!)

      described_class.new.perform(programme, cohort_import)
    end

    it "assigns the programme to the immunisation import and processes it" do
      allow(immunisation_import).to receive(:parse_rows!)
      allow(immunisation_import).to receive(:process!)

      expect(immunisation_import).to receive(:programme=).with(programme)
      expect(immunisation_import).to receive(:parse_rows!)
      expect(immunisation_import).to receive(:process!)

      described_class.new.perform(programme, immunisation_import)
    end
  end
end
