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

    it { should eq({ prefix: "HPV", text: "No response", colour: "grey" }) }
  end

  describe "#programme" do
    subject(:hash) { patient_status_resolver.programme }

    let(:programme) { Programme.hpv }
    let(:session) { create(:session, programmes: [programme]) }

    it { should eq({ prefix: "HPV", text: "Not eligible", colour: "grey" }) }

    context "when triaged to delay vaccination" do
      around { |example| freeze_time(Date.new(2025, 10, 29)) { example.run } }

      let(:patient) do
        create(:patient, :consent_given_triage_delay_vaccination, session:)
      end

      it do
        expect(hash).to eq(
          {
            prefix: "HPV",
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
            prefix: "HPV",
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
            prefix: "HPV",
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
          { prefix: "HPV", text: "Due vaccination", colour: "green" }
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
              prefix: "MMR",
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
            {
              prefix: "MMR",
              text: "Due 1st dose",
              colour: "green",
              details_text: "No preference"
            }
          )
        end
      end

      context "and due 1st dose gelatine-free" do
        let(:patient) do
          create(
            :patient,
            :consent_given_without_gelatine_triage_not_needed,
            session:
          )
        end

        before do
          StatusUpdater.call(patient:)
          patient.reload
        end

        it do
          expect(hash).to eq(
            {
              prefix: "MMR",
              text: "Due 1st dose",
              colour: "green",
              details_text: "Gelatine-free vaccine only"
            }
          )
        end
      end
    end
  end

  describe "#triage" do
    subject(:hash) { patient_status_resolver.triage }

    let(:programme) { Programme.hpv }

    it do
      expect(hash).to eq(
        { prefix: "HPV", text: "No triage needed", colour: "grey" }
      )
    end
  end
end
