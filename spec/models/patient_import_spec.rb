# frozen_string_literal: true

describe PatientImport do
  let(:klass) do
    Class.new(described_class) do
      self.table_name = "cohort_imports"
      def self.model_name
        ActiveModel::Name.new(self, nil, "PatientImportTest")
      end
    end
  end

  describe "#generate_other_rows_text" do
    let(:import) { klass.new }
    let(:duplicate_rows) do
      duplicate_row_numbers.map do
        build(:patient_changeset, import:, row_number: it)
      end
    end

    context "with only two duplicate rows" do
      let(:duplicate_row_numbers) { [0, 1] }

      it "correctly lists only one row" do
        current_row = duplicate_rows.first
        expect(
          import.send(:generate_other_rows_text, current_row, duplicate_rows)
        ).to eq("row 3")
      end
    end

    context "with 10 duplicate rows" do
      let(:duplicate_row_numbers) { [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] }

      it "includes count rows from the current one" do
        current_row = duplicate_rows.last
        expect(
          import.send(:generate_other_rows_text, current_row, duplicate_rows)
        ).to eq("rows 6, 7, 8, 9 and 10")
      end

      it "lists rows after the current one if it's at the beginning" do
        current_row = duplicate_rows[1]
        expect(
          import.send(:generate_other_rows_text, current_row, duplicate_rows)
        ).to eq("rows 2, 4, 5, 6 and 7")
      end
    end
  end
end
