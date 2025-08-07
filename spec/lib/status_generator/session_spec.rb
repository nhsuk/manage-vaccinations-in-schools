# frozen_string_literal: true

describe StatusGenerator::Session do
  subject(:generator) do
    described_class.new(
      session_id: patient_session.session_id,
      academic_year: patient_session.academic_year,
      session_attendance: patient_session.session_attendances.last,
      programme_id: programme.id,
      consents: patient.consents,
      triages: patient.triages,
      vaccination_records: patient.vaccination_records
    )
  end

  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:programme) { create(:programme) }

  describe "#status" do
    subject(:status) { generator.status }

    let(:patient) { patient_session.patient }
    let(:session) { patient_session.session }

    context "with no vaccination record" do
      it { should be(:none_yet) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, session:, programme:) }

      it { should be(:vaccinated) }
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

      it { should be(:unwell) }
    end

    context "with a discarded vaccination administered" do
      before do
        create(:vaccination_record, :discarded, patient:, session:, programme:)
      end

      it { should be(:none_yet) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:refused) }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :refused, patient:, programme:)

        parent = create(:parent_relationship, patient:).parent
        create(:consent, :given, patient:, programme:, parent:)
      end

      it { should be(:none_yet) }
    end

    context "when triaged as do not vaccinate" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:had_contraindications) }
    end

    context "when not attending the session" do
      before { create(:session_attendance, :absent, patient_session:) }

      it { should be(:absent_from_session) }
    end
  end
end
