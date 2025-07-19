# frozen_string_literal: true

shared_examples_for "a model that belongs to an academic year" do |attribute|
  describe "#academic_year" do
    let(:examples) do
      {
        Date.new(2020, 9, 1) => 2020,
        Date.new(2021, 8, 31) => 2020,
        Date.new(2021, 9, 1) => 2021,
        Date.new(2022, 8, 31) => 2021
      }
    end

    examples.each do |date, academic_year|
      context "with #{date}" do
        before { subject[attribute] = date }

        it { expect(subject.academic_year).to eq(academic_year) }
      end
    end
  end

  describe "#for_academic_year" do
    before { subject.save! }

    it "returns the correct records" do
      academic_year = subject.academic_year

      expect(described_class.for_academic_year(academic_year)).to include(
        subject
      )

      expect(
        described_class.for_academic_year(academic_year + 1)
      ).not_to include(subject)
    end
  end
end
