# frozen_string_literal: true

describe PatientStatusResolver do
  subject(:status_attached_tag_resolver) do
    described_class.new(patient, programme:, academic_year:)
  end

  let(:patient) { create(:patient) }
  let(:academic_year) { AcademicYear.current }

  describe "#consent" do
    subject { status_attached_tag_resolver.consent }

    let(:programme) { create(:programme, :hpv) }

    it { should eq({ text: "No response", colour: "grey" }) }
  end

  describe "#triage" do
    subject { status_attached_tag_resolver.triage }

    let(:programme) { create(:programme, :hpv) }

    it { should eq({ text: "No triage needed", colour: "grey" }) }
  end

  describe "#vaccination" do
    subject(:hash) { status_attached_tag_resolver.vaccination }

    let(:programme) { create(:programme, :hpv) }

    it { should eq({ text: "Not eligible", colour: "grey" }) }

    context "and due" do
      let(:session) { create(:session, programmes: [programme]) }
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      it do
        expect(hash).to eq(
          {
            text: "Due vaccination",
            colour: "white",
            details_text: "Consent given"
          }
        )
      end
    end

    context "for MMR programme" do
      let(:programme) { create(:programme, :mmr) }
      let(:session) { create(:session, programmes: [programme]) }

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
              colour: "white",
              details_text: "Consent given"
            }
          )
        end
      end
    end
  end
end
