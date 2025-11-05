# frozen_string_literal: true

describe StatusGenerator::Vaccination do
  subject(:generator) do
    described_class.new(
      programme:,
      academic_year: AcademicYear.current,
      patient:,
      patient_locations:
        patient.patient_locations.includes(
          location: :location_programme_year_groups
        ),
      consents: patient.consents,
      triages: patient.triages,
      attendance_record: patient.attendance_records.first,
      vaccination_records:
        patient.vaccination_records.order(performed_at: :desc)
    )
  end

  let(:patient) { create(:patient) }
  let(:programme) { CachedProgramme.sample }
  let(:session) { create(:session, programmes: [programme]) }

  describe "#status" do
    subject { generator.status }

    context "with no vaccination record" do
      it { should be(:not_eligible) }
    end

    context "with a flu programme" do
      let(:programme) { CachedProgramme.flu }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(:eligible) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(:due) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(:due) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:not_eligible) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(:vaccinated) }
      end

      context "with an already had vaccination record" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end

      context "with an administered vaccination record from last year" do
        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 1.year.ago
          )
        end

        it { should be(:not_eligible) }
      end

      context "with an already had vaccination record from last year" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            performed_at: 1.year.ago
          )
        end

        it { should be(:not_eligible) }
      end
    end

    context "with an HPV programme" do
      let(:programme) { CachedProgramme.hpv }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(:eligible) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(:due) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(:due) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:not_eligible) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(:vaccinated) }
      end

      context "with an already had vaccination record" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end
    end

    context "with a MenACWY programme" do
      let(:programme) { CachedProgramme.menacwy }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(:eligible) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(:due) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(:due) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:not_eligible) }
      end

      context "with an administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(:vaccinated) }
      end

      context "with a second dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 2,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end

      context "with an administered vaccination record when the patient was younger than 10 years old" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(:not_eligible) }
      end

      context "with an already had vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end
    end

    context "with an MMR programme" do
      let(:programme) { CachedProgramme.mmr }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(:eligible) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(:due) }
      end

      context "with a valid first dose" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 1.year
          )
        end

        it { should be(:eligible) }

        context "and then triaged as safe to vaccinate" do
          before { create(:triage, :safe_to_vaccinate, patient:, programme:) }

          it { should be(:due) }

          context "and a valid second dose" do
            before do
              create(
                :vaccination_record,
                patient:,
                programme:,
                performed_at: patient.date_of_birth + 1.year + 3.months
              )
            end

            it { should be(:vaccinated) }
          end
        end
      end
    end

    context "with an Td/IPV programme" do
      let(:programme) { CachedProgramme.td_ipv }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(:eligible) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(:due) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(:due) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:not_eligible) }
      end

      context "with a first dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:
          )
        end

        it { should be(:not_eligible) }
      end

      context "with a first dose administered vaccination record when the patient was younger than 10 years old" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(:not_eligible) }
      end

      context "with a fifth dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end

      context "with a fifth dose administered vaccination record when the patient was younger than 10 years old" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(:not_eligible) }
      end

      context "with an unknown dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:
          )
        end

        it { should be(:not_eligible) }
      end

      context "with an unknown dose administered vaccination record recorded in a session" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:,
            session: create(:session, programmes: [programme])
          )
        end

        it { should be(:vaccinated) }
      end

      context "with an already had vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end
    end

    context "with a discarded vaccination administered" do
      before { create(:vaccination_record, :discarded, patient:, programme:) }

      it { should be(:not_eligible) }
    end
  end

  describe "#dose_sequence" do
    subject(:dose_sequence) { generator.dose_sequence }

    it { should be_nil }

    context "for MMR programme" do
      let(:programme) { CachedProgramme.mmr }
      let(:session) { create(:session, programmes: [programme]) }
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      it { should eq(1) }

      context "with an existing vaccination record" do
        before do
          create(:vaccination_record, patient:, programme:, dose_sequence: 1)
        end

        it { should eq(2) }
      end
    end
  end

  describe "#latest_date" do
    subject(:date) { generator.latest_date }

    let(:performed_at) { 1.day.ago.to_date }
    let(:created_at) { 2.days.ago.to_date }

    let(:programme) { CachedProgramme.hpv }

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

        it { should eq(later_date) }
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

        it { should eq(later_date) }
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
  end

  describe "#latest_location_id" do
    subject { generator.latest_location_id }

    context "with a flu programme" do
      let(:programme) { CachedProgramme.flu }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with an administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an administered vaccination record from last year" do
        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 1.year.ago
          )
        end

        it { should be_nil }
      end

      context "with an already had vaccination record from last year" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            performed_at: 1.year.ago
          )
        end

        it { should be_nil }
      end
    end

    context "with an HPV programme" do
      let(:programme) { CachedProgramme.hpv }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with an administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end
    end

    context "with a MenACWY programme" do
      let(:programme) { CachedProgramme.menacwy }
      let(:patient) { create(:patient, programmes: [programme]) }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with an administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with a second dose administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 2,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an administered vaccination record when the patient was younger than 10 years old" do
        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be_nil }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end
    end

    context "with an Td/IPV programme" do
      let(:programme) { CachedProgramme.td_ipv }
      let(:patient) { create(:patient, date_of_birth: 15.years.ago.to_date) }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with a first dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:
          )
        end

        it { should be_nil }
      end

      context "with a first dose administered vaccination record when the patient was younger than 10 years old" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be_nil }
      end

      context "with a fifth dose administered vaccination record" do
        let(:location) { create(:school) }
        let(:patient) { create(:patient, date_of_birth: 15.years.ago.to_date) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with a fifth dose administered vaccination record when the patient was younger than 10 years old" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be_nil }
      end

      context "with an unknown dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:
          )
        end

        it { should be_nil }
      end

      context "with an unknown dose administered vaccination record recorded in a session" do
        let(:location) { create(:school, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:,
            session: create(:session, location:, programmes: [programme])
          )
        end

        it { should be(location.id) }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end
    end
  end

  describe "#latest_session_status" do
    subject(:latest_session_status) { generator.latest_session_status }

    let(:programme) { CachedProgramme.hpv }
    let(:patient) { create(:patient, session:) }

    context "with no vaccination record" do
      it { should be_nil }
    end

    context "with a vaccination already had" do
      before do
        create(
          :vaccination_record,
          :already_had,
          patient:,
          session:,
          programme:
        )
      end

      it { should be(:already_had) }
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

    context "when not attending the session" do
      before { create(:attendance_record, :absent, patient:, session:) }

      it { should be(:absent) }
    end

    context "with two vaccination records" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          outcome: "refused",
          patient:,
          session:,
          programme:,
          performed_at: 1.week.ago
        )
        create(
          :vaccination_record,
          :not_administered,
          outcome: "not_well",
          patient:,
          session:,
          programme:,
          performed_at: 2.weeks.ago
        )
      end

      it "picks the most recent record" do
        expect(latest_session_status).to eq(:refused)
      end
    end
  end
end
