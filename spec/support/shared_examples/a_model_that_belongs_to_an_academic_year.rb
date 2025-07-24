# frozen_string_literal: true

shared_examples_for "a model that belongs to an academic year" do
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
