# frozen_string_literal: true

describe AppPatientSessionVaccinationComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient:, session:, programme:) }

  let(:programme) { Programme.hpv }
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
      before { create(:vaccination_record, patient:, programme: Programme.mmr) }

      it { should be(false) }
    end
  end

  context "when programme status is enabled" do
    before { Flipper.enable(:programme_status) }

    context "with a vaccination record for the programme" do
      before do
        create(:vaccination_record, patient:, programme:)
        StatusUpdater.call(patient:)
      end

      it { should have_text("HPV: Vaccinated") }
    end

    context "with an unwell vaccination record for the programme" do
      before do
        create(:vaccination_record, :unwell, patient:, programme:)
        StatusUpdater.call(patient:)
      end

      it { should have_text("HPV: Unable to vaccinate") }
    end
  end
end
