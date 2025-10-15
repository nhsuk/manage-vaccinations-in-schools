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
    subject { status_attached_tag_resolver.vaccination }

    let(:programme) { create(:programme, :hpv) }

    it { should eq({ text: "Not eligible", colour: "grey" }) }
  end
end
