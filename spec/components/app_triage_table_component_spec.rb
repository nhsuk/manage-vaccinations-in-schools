# frozen_string_literal: true

describe AppTriageTableComponent do
  let(:component) { described_class.new(patient_session:, programme:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:patient) { patient_session.patient }

  before { patient.strict_loading!(false) }

  describe "#render?" do
    subject(:render?) { component.render? }

    it { should be(false) }

    context "with a triage response" do
      before { create(:triage, patient:, programme:) }

      it { should be(true) }
    end
  end

  describe "rendered component" do
    subject { render_inline(component) }

    context "triaged as safe to vaccinate" do
      let!(:triage) do
        create(:triage, :ready_to_vaccinate, patient:, programme:)
      end

      it { should have_css("caption", text: "Triage notes") }
      it { should have_content("Safe to vaccinate") }
      it { should have_content(triage.performed_by.full_name) }
    end

    context "triaged as unsafe to vaccinate" do
      let!(:triage) { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should have_css("caption", text: "Triage notes") }
      it { should have_content("Do not vaccinate") }
      it { should have_content(triage.performed_by.full_name) }
    end
  end
end
