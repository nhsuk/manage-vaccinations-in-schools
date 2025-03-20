# frozen_string_literal: true

describe SearchForm do
  subject(:form) do
    described_class.new(
      consent_status:,
      date_of_birth_day:,
      date_of_birth_month:,
      date_of_birth_year:,
      missing_nhs_number:,
      programme_status:,
      q:,
      register_status:,
      session_status:,
      triage_status:,
      year_groups:
    )
  end

  let(:consent_status) { nil }
  let(:date_of_birth_day) { Date.current.day }
  let(:date_of_birth_month) { Date.current.month }
  let(:date_of_birth_year) { Date.current.year }
  let(:missing_nhs_number) { true }
  let(:programme_status) { nil }
  let(:q) { "query" }
  let(:register_status) { nil }
  let(:session_status) { nil }
  let(:triage_status) { nil }
  let(:year_groups) { %w[8 9 10 11] }

  context "for patients" do
    let(:scope) { Patient.all }

    let(:outcomes) { Outcomes.new(patients: scope) }

    it "doesn't raise an error" do
      expect { form.apply(scope, outcomes:) }.not_to raise_error
    end

    context "filtering on date of birth" do
      let(:consent_status) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:patient) { create(:patient, date_of_birth: Date.new(2000, 1, 1)) }

      context "with only a year specified" do
        let(:date_of_birth_year) { 2000 }

        it "includes the patient" do
          expect(form.apply(scope, outcomes:)).to include(patient)
        end
      end

      context "with only a month specified" do
        let(:date_of_birth_month) { 1 }

        it "includes the patient" do
          expect(form.apply(scope, outcomes:)).to include(patient)
        end
      end

      context "with only a day specified" do
        let(:date_of_birth_day) { 1 }

        it "includes the patient" do
          expect(form.apply(scope, outcomes:)).to include(patient)
        end
      end

      context "with all parts specified" do
        let(:date_of_birth_year) { 2000 }
        let(:date_of_birth_month) { 1 }
        let(:date_of_birth_day) { 1 }

        it "includes the patient" do
          expect(form.apply(scope, outcomes:)).to include(patient)
        end
      end
    end

    context "filtering on programme status" do
      let(:consent_status) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { "vaccinated" }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:programme) { create(:programme) }

      it "filters on session status" do
        patient = create(:patient, :vaccinated, programmes: [programme])
        expect(form.apply(scope, outcomes:, programme:)).to include(patient)
      end
    end
  end

  context "for patient sessions" do
    let(:scope) { PatientSession.preload_for_status }
    let(:outcomes) { Outcomes.new(patient_sessions: scope) }

    it "doesn't raise an error" do
      expect { form.apply(scope, outcomes:) }.not_to raise_error
    end

    context "filtering on consent status" do
      let(:consent_status) { "given" }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on consent status" do
        patient_session =
          create(:patient_session, :consent_given_triage_not_needed)
        expect(form.apply(scope, outcomes:)).to include(patient_session)
      end
    end

    context "filtering on session status" do
      let(:consent_status) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { "administered" }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on session status" do
        patient_session = create(:patient_session, :vaccinated)
        expect(form.apply(scope, outcomes:)).to include(patient_session)
      end
    end

    context "filtering on register status" do
      let(:consent_status) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { "attending" }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on register status" do
        patient_session = create(:patient_session, :in_attendance)
        expect(form.apply(scope, outcomes:)).to include(patient_session)
      end
    end

    context "filtering on triage status" do
      let(:consent_status) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { "required" }
      let(:year_groups) { nil }

      it "filters on triage status" do
        patient_session = create(:patient_session, :consent_given_triage_needed)
        expect(form.apply(scope, outcomes:)).to include(patient_session)
      end
    end
  end
end
