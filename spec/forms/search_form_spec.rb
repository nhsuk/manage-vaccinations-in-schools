# frozen_string_literal: true

describe SearchForm do
  subject(:form) do
    described_class.new(
      consent_status:,
      date_of_birth:,
      missing_nhs_number:,
      q:,
      year_groups:
    )
  end

  let(:consent_status) { nil }
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
    let(:scope) { PatientSession.preload_for_status }

    it "doesn't raise an error" do
      expect { form.apply(scope) }.not_to raise_error
    end

    context "filtering on consent status" do
      let(:consent_status) { "given" }
      let(:date_of_birth) { nil }
      let(:missing_nhs_number) { nil }
      let(:q) { nil }
      let(:year_groups) { nil }

      it "filters on consent status" do
        patient_session =
          create(:patient_session, :consent_given_triage_not_needed)
        expect(form.apply(scope)).to include(patient_session)
      end
    end
  end
end
