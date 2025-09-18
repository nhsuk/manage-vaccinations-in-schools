# frozen_string_literal: true

describe AppPatientSessionTriageComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(patient:, session:, programme:, current_user:)
  end

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }
  let(:current_user) { create(:nurse) }

  before { stub_authorization(allowed: true) }

  context "without triage" do
    it { should_not have_link("Update triage outcome") }
  end

  context "when triaged as safe to vaccinate" do
    before do
      create(:triage, :ready_to_vaccinate, patient:, programme:)
      create(:patient_triage_status, :safe_to_vaccinate, patient:, programme:)
    end

    it do
      expect(rendered).to have_css(
        ".app-card__heading--aqua-green",
        text: "Safe to vaccinate"
      )
    end

    it { should have_content("safe to vaccinate") }
    it { should have_link("Update triage outcome") }
  end

  context "when triaged as unsafe to vaccinate" do
    before do
      create(:triage, :do_not_vaccinate, patient:, programme:)
      create(:patient_triage_status, :do_not_vaccinate, patient:, programme:)
    end

    it { should have_css(".app-card__heading--red", text: "Do not vaccinate") }
    it { should have_content("should not be vaccinated") }
    it { should have_link("Update triage outcome") }
  end
end
