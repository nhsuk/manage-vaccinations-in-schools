# frozen_string_literal: true

describe AppTriageTableComponent do
  let(:component) { described_class.new(patient:, session:, programme:) }

  let(:programme) { Programme.sample }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  before { patient.strict_loading!(false) }

  describe "#render?" do
    subject { component.render? }

    it { should be(false) }

    context "with a triage response" do
      before { create(:triage, :safe_to_vaccinate, patient:, programme:) }

      it { should be(true) }
    end
  end

  describe "rendered component" do
    subject { render_inline(component) }

    context "triaged as safe to vaccinate" do
      before { create(:triage, :safe_to_vaccinate, patient:, programme:) }

      it { should have_css("caption", text: "Triage notes") }
      it { should have_content("Safe to vaccinate") }
    end

    context "triaged as unsafe to vaccinate" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should have_css("caption", text: "Triage notes") }
      it { should have_content("Do not vaccinate") }
    end

    context "with a performed by user" do
      before do
        create(:triage, :safe_to_vaccinate, patient:, programme:, performed_by:)
      end

      let(:performed_by) { create(:nurse) }

      it { should have_content(performed_by.full_name) }
    end
  end
end
