# frozen_string_literal: true

describe ProcessImportJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform(import) }

    after { perform }

    context "with a class import" do
      let(:import) { create(:class_import) }

      it "parses and processes the rows" do
        expect(import).to receive(:parse_rows!)
        expect(import).to receive(:process!)
      end
    end

    context "with a cohort import" do
      let(:import) { create(:cohort_import) }

      it "parses and processes the rows" do
        expect(import).to receive(:parse_rows!)
        expect(import).to receive(:process!)
      end
    end

    context "with an immunisation import" do
      let(:import) { create(:immunisation_import) }

      it "parses and processes the rows" do
        expect(import).to receive(:parse_rows!)
        expect(import).to receive(:process!)
      end
    end
  end
end
