# frozen_string_literal: true

describe AppPatientSessionOutcomeComponent do
  let(:component) { described_class.new(patient:, session:, programme:) }

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  describe "#render?" do
    subject { component.render? }

    it { should be(false) }

    context "with a vaccination record for the programme" do
      before { create(:vaccination_record, patient:, programme:) }

      it { should be(true) }
    end

    context "with a vaccination record for a different programme" do
      before do
        create(
          :vaccination_record,
          patient:,
          programme: create(:programme, :mmr)
        )
      end

      it { should be(false) }
    end
  end
end
