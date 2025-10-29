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

    context "with details" do
      let(:session) { create(:session, programmes: [programme]) }
      let(:patient) do
        create(:patient, :consent_given_triage_not_needed, session:)
      end

      it do
        expect(hash).to eq(
          { text: "Due", colour: "white", details_text: "Consent given" }
        )
      end
    end

    context "for MMR programme" do
      let(:programme) { create(:programme, :mmr) }

      context "and eligible for 1st dose" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        before { StatusUpdater.call(patient:) }

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
    end
  end
end
