# frozen_string_literal: true

describe SearchForm do
  subject(:form) do
    described_class.new(date_of_birth:, missing_nhs_number:, q:, year_groups:)
  end

  let(:date_of_birth) { Date.current }
  let(:missing_nhs_number) { true }
  let(:q) { "query" }
  let(:year_groups) { %w[8 9 10 11] }

  context "for patients" do
    it "doesn't raise an error" do
      expect { form.apply(Patient.all) }.not_to raise_error
    end
  end

  context "for patient sessions" do
    it "doesn't raise an error" do
      expect { form.apply(PatientSession.all) }.not_to raise_error
    end
  end
end
