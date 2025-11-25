# frozen_string_literal: true

describe PatientStatusResolver do
  subject(:patient_status_resolver) do
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
    subject { patient_status_resolver.consent }

    let(:programme) { Programme.hpv }

    it { should eq({ text: "No response", colour: "grey" }) }
  end

  describe "#programme" do
    subject(:hash) { patient_status_resolver.programme }

    let(:programme) { Programme.hpv }
    let(:session) { create(:session, programmes: [programme]) }

    it { should eq({ text: "Not eligible", colour: "grey" }) }

    context "when triaged to delay vaccination" do
      around { |example| freeze_time(Date.new(2025, 10, 29)) { example.run } }

      let(:patient) do
        create(:patient, :consent_given_triage_delay_vaccination, session:)
      end

      it do
        expect(hash).to eq(
          {
            text: "Unable to vaccinate",
            colour: "red",
            details_text: "Delay vaccination until 30 October 2025"
          }
        )
      end
    end

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
            colour: "white",
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
            colour: "white",
            details_text: "Already had the vaccine"
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
            colour: "green",
            details_text: "Vaccination"
          }
        )
      end
    end

    context "for MMR programme" do
      let(:programme) { Programme.mmr }

      context "and eligible for 1st dose" do
        let(:patient) { create(:patient, session:) }

        before do
          StatusUpdater.call(patient:)
          patient.reload
        end

        it do
          expect(hash).to eq(
            {
              text: "Needs consent",
              colour: "blue",
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
            { text: "Due 1st dose", colour: "green", details_text: "Injection" }
          )
        end
      end
    end
  end

  describe "#triage" do
    subject { patient_status_resolver.triage }

    let(:programme) { Programme.hpv }

    it { should eq({ text: "No triage needed", colour: "grey" }) }
  end

  describe "#vaccination" do
    subject(:hash) { patient_status_resolver.vaccination }

    let(:programme) { Programme.hpv }
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
      let(:programme) { Programme.mmr }

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
