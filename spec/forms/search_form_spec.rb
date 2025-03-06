# frozen_string_literal: true

describe SearchForm do
  subject(:form) do
    described_class.new(
      consent_status:,
      date_of_birth:,
      missing_nhs_number:,
      q:,
      record_status:,
      register_status:,
      triage_status:,
      year_groups:
    )
  end

  let(:consent_status) { nil }
  let(:date_of_birth) { Date.current }
  let(:missing_nhs_number) { true }
  let(:q) { "query" }
  let(:record_status) { nil }
  let(:register_status) { nil }
  let(:triage_status) { nil }
  let(:year_groups) { %w[8 9 10 11] }

  context "with invalid date parameters" do
    subject(:form) do
      described_class.new(
        "date_of_birth(1i)": "invalid",
        "date_of_birth(2i)": "value",
        "date_of_birth(3i)": "12345"
      )
    end

    it "doesn't raise an error" do
      expect { form }.not_to raise_error
    end

    it "doesn't filter by date" do
      expect(form.date_of_birth).to be_nil
    end
  end

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
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on consent status" do
        patient_session =
          create(:patient_session, :consent_given_triage_not_needed)
        expect(form.apply(scope)).to include(patient_session)
      end
    end

    context "filtering on record status" do
      let(:consent_status) { nil }
      let(:date_of_birth) { nil }
      let(:missing_nhs_number) { nil }
      let(:q) { nil }
      let(:record_status) { "administered" }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on record status" do
        patient_session = create(:patient_session, :vaccinated)
        expect(form.apply(scope)).to include(patient_session)
      end
    end

    context "filtering on register status" do
      let(:consent_status) { nil }
      let(:date_of_birth) { nil }
      let(:missing_nhs_number) { nil }
      let(:q) { nil }
      let(:record_status) { nil }
      let(:register_status) { "present" }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on register status" do
        patient_session = create(:patient_session, :in_attendance)
        expect(form.apply(scope)).to include(patient_session)
      end
    end

    context "filtering on triage status" do
      let(:consent_status) { nil }
      let(:date_of_birth) { nil }
      let(:missing_nhs_number) { nil }
      let(:q) { nil }
      let(:record_status) { nil }
      let(:register_status) { nil }
      let(:triage_status) { "required" }
      let(:year_groups) { nil }

      it "filters on triage status" do
        patient_session = create(:patient_session, :consent_given_triage_needed)
        expect(form.apply(scope)).to include(patient_session)
      end
    end
  end
end
