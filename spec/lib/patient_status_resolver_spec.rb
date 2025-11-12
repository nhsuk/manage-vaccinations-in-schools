# frozen_string_literal: true

describe PatientStatusResolver do
  subject(:status_attached_tag_resolver) do
    described_class.new(
      Patient.includes_statuses.find(patient.id),
      programme:,
      academic_year:,
      context_location_id:
    )
  end

  let(:patient) { create(:patient) }
  let(:academic_year) { AcademicYear.current }
  let(:context_location_id) { nil }

  describe "#consent" do
    subject { status_attached_tag_resolver.consent }

    let(:programme) { CachedProgramme.hpv }

    it { should eq({ text: "No response", colour: "grey" }) }
  end

  describe "#triage" do
    subject { status_attached_tag_resolver.triage }

    let(:programme) { CachedProgramme.hpv }

    it { should eq({ text: "No triage needed", colour: "grey" }) }
  end

  describe "#vaccination" do
    subject(:hash) { status_attached_tag_resolver.vaccination }

    let(:programme) { CachedProgramme.hpv }
    let(:session) { create(:session, programmes: [programme]) }

    it { should eq({ text: "Not eligible", colour: "grey" }) }

    context "with an administered vaccination record" do
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      before do
        create(
          :vaccination_record,
          :administered,
          patient:,
          programme:,
          performed_at: Time.zone.local(2025, 10, 30)
        )
        StatusUpdater.call(patient:)
        patient.reload
      end

      it do
        expect(hash).to eq(
          {
            text: "Vaccinated",
            colour: "green",
            details_text: "Vaccinated on 30 October 2025"
          }
        )
      end
    end

    context "with an already had vaccination record" do
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      before do
        create(:vaccination_record, :already_had, patient:, programme:)
        StatusUpdater.call(patient:)
        patient.reload
      end

      it do
        expect(hash).to eq(
          {
            text: "Vaccinated",
            colour: "green",
            details_text: "Already had the vaccine"
          }
        )
      end
    end

    context "with a vaccinated elsewhere vaccination record" do
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      let(:context_location_id) { session.location_id }

      before do
        create(
          :vaccination_record,
          patient:,
          programme:,
          location: create(:school, name: "Different school")
        )
        StatusUpdater.call(patient:)
        patient.reload
      end

      it do
        expect(hash).to eq(
          {
            text: "Vaccinated",
            colour: "green",
            details_text: "Vaccinated at Different school"
          }
        )
      end
    end

    context "and due" do
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      it do
        expect(hash).to eq(
          {
            text: "Due vaccination",
            colour: "aqua-green",
            details_text: "Consent given"
          }
        )
      end
    end

    context "for MMR programme" do
      let(:programme) { CachedProgramme.mmr }

      context "and eligible for 1st dose" do
        let(:patient) { create(:patient, session:) }

        before do
          StatusUpdater.call(patient:)
          patient.reload
        end

        it do
          expect(hash).to eq(
            {
              text: "Eligible for 1st dose",
              colour: "white",
              details_text: "No response"
            }
          )
        end
      end

      context "and due 1st dose" do
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          StatusUpdater.call(patient:)
          patient.reload
        end

        it do
          expect(hash).to eq(
            {
              text: "Due 1st dose",
              colour: "aqua-green",
              details_text: "Consent given"
            }
          )
        end
      end
    end
  end
end
