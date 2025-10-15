# frozen_string_literal: true

describe StatusGenerator::Session do
  subject(:generator) do
    described_class.new(
      session_id: session.id,
      academic_year: session.academic_year,
      attendance_record: patient.attendance_records.last,
      programme:,
      patient:,
      consents: patient.consents,
      triages: patient.triages,
      vaccination_records: patient.vaccination_records
    )
  end

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  describe "#status" do
    subject(:status) { generator.status }

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

      it { should be(:conflicting_consent) }
    end

    context "when triaged as do not vaccinate" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:had_contraindications) }
    end

    context "when not attending the session" do
      before { create(:attendance_record, :absent, patient:, session:) }

      it { should be(:absent_from_session) }
    end
  end

  describe "#date" do
    subject(:date) { generator.date }

    around { |example| travel_to(Time.zone.now) { example.run } }

    let(:performed_at) { 1.day.ago.to_date }
    let(:created_at) { 2.days.ago.to_date }

    context "with a vaccination administered" do
      before do
        create(
          :vaccination_record,
          patient:,
          session:,
          programme:,
          performed_at:
        )
      end

      it { should eq(performed_at.to_date) }
    end

    context "with a vaccination already had" do
      before do
        create(
          :vaccination_record,
          :already_had,
          patient:,
          session:,
          programme:,
          performed_at: performed_at
        )
      end

      it { should eq(performed_at.to_date) }
    end

    context "with contraindications from vaccination record" do
      before do
        create(
          :vaccination_record,
          :contraindications,
          patient:,
          session:,
          programme:,
          performed_at: performed_at
        )
      end

      it { should eq(performed_at.to_date) }
    end

    context "with contraindications from triage" do
      before do
        create(
          :triage,
          :do_not_vaccinate,
          patient: patient,
          programme: programme,
          created_at:
        )
      end

      it { should eq(created_at.to_date) }
    end

    context "with contraindications from both vaccination record and triage" do
      let(:earlier_date) { 3.days.ago.to_date }
      let(:later_date) { 1.day.ago.to_date }

      context "when vaccination record date is earlier" do
        before do
          create(
            :vaccination_record,
            :contraindications,
            patient:,
            session:,
            programme:,
            performed_at: earlier_date
          )

          create(:triage, :do_not_vaccinate, patient:, programme:, created_at:)
        end

        it { should eq(earlier_date) }
      end

      context "when triage date is earlier" do
        before do
          create(
            :vaccination_record,
            :contraindications,
            patient:,
            session:,
            programme:,
            performed_at: later_date
          )

          create(
            :triage,
            :do_not_vaccinate,
            patient:,
            programme:,
            created_at: earlier_date
          )
        end

        it { should eq(earlier_date) }
      end
    end

    context "with refused from vaccination record" do
      before do
        create(
          :vaccination_record,
          :refused,
          patient:,
          session:,
          programme:,
          performed_at:
        )
      end

      it { should eq(performed_at.to_date) }
    end

    context "with refused from consent" do
      before do
        consent =
          create(:consent, :refused, patient: patient, programme: programme)
        consent.update_column(:submitted_at, created_at)
      end

      it { should eq(created_at) }
    end

    context "with refused from both vaccination record and consent" do
      let(:vaccination_record_date) { 1.day.ago }
      let(:consent_date) { 3.days.ago }

      before do
        create(
          :vaccination_record,
          :refused,
          patient: patient,
          session: session,
          programme: programme,
          performed_at: vaccination_record_date
        )

        create(
          :consent,
          :refused,
          patient: patient,
          programme: programme,
          submitted_at: consent_date
        )
      end

      it { should eq(vaccination_record_date.to_date) }
    end

    context "with absent from vaccination record" do
      before do
        create(
          :vaccination_record,
          :absent_from_session,
          patient:,
          session:,
          programme:,
          performed_at:
        )
      end

      it { should eq(performed_at.to_date) }
    end

    context "with absent from session attendance" do
      before do
        create(:attendance_record, :absent, patient:, session:, created_at:)
      end

      it { should eq(created_at) }
    end

    context "with absent from both vaccination record and session attendance" do
      let(:earlier_date) { 3.days.ago.to_date }
      let(:later_date) { 1.day.ago.to_date }

      context "when vaccination record date is earlier" do
        before do
          create(
            :vaccination_record,
            :absent_from_session,
            patient:,
            session:,
            programme:,
            performed_at: earlier_date
          )

          create(
            :attendance_record,
            :absent,
            patient:,
            session:,
            created_at: later_date
          )
        end

        it { should eq(earlier_date) }
      end

      context "when session attendance date is earlier" do
        before do
          create(
            :vaccination_record,
            :absent_from_session,
            patient:,
            session:,
            programme:,
            performed_at: later_date
          )

          create(
            :attendance_record,
            :absent,
            patient:,
            session:,
            created_at: earlier_date
          )
        end

        it { should eq(earlier_date) }
      end
    end

    context "with unwell" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          patient:,
          session:,
          programme:,
          performed_at:
        )
      end

      it { should eq(performed_at.to_date) }
    end

    context "with no status" do
      it { should eq(session.academic_year.to_academic_year_date_range.begin) }
    end
  end
end
