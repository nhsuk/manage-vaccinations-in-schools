# frozen_string_literal: true

describe ProcessCohortImportJob do
  let(:programme) { create(:programme) }
  let(:cohort_import) { create(:cohort_import) }

  describe "#perform" do
    it "assigns the programme to the cohort import and processes it" do
      allow(CohortImport).to receive(:find).and_return(cohort_import)
      allow(Programme).to receive(:find).and_return(programme)
      expect(cohort_import).to receive(:programme=).with(programme)
      expect(cohort_import).to receive(:process!)

      described_class.new.perform(programme, cohort_import)
    end
  end
end
