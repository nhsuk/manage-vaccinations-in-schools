# frozen_string_literal: true

describe SessionOutcome do
  subject(:instance) do
    described_class.new(
      patient_sessions: PatientSession.all,
      consent_outcome:,
      register_outcome:,
      triage_outcome:
    )
  end

  let(:consent_outcome) { ConsentOutcome.new(patients: Patient.all) }
  let(:register_outcome) do
    RegisterOutcome.new(patient_sessions: PatientSession.all)
  end
  let(:triage_outcome) do
    TriageOutcome.new(
      patients: Patient.all,
      consent_outcome:,
      vaccinated_criteria:
    )
  end
  let(:vaccinated_criteria) { VaccinatedCriteria.new(patients: Patient.all) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient_session) { create(:patient_session, patient:, session:) }

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status(patient_session, programme:) }

    context "with no vaccination record" do
      it { should be(described_class::NONE_YET) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, session:, programme:) }

      it { should be(described_class::VACCINATED) }
    end

    context "with a vaccination not administered" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          patient:,
          session:,
          programme:
        )
      end

      it { should be(described_class::UNWELL) }
    end

    context "with a discarded vaccination administered" do
      before do
        create(:vaccination_record, :discarded, patient:, session:, programme:)
      end

      it { should be(described_class::NONE_YET) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(described_class::REFUSED) }
    end

    context "when triaged as do not vaccinate" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(described_class::HAD_CONTRAINDICATIONS) }
    end

    context "when not attending the session" do
      before { create(:session_attendance, :absent, patient_session:) }

      it { should be(described_class::ABSENT_FROM_SESSION) }
    end
  end
end
