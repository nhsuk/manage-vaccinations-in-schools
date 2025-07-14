# frozen_string_literal: true

describe AppPatientSessionConsentComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient_session, programme:) }

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient_session) { create(:patient_session, session:) }
  let(:patient) { patient_session.patient }

  before do
    patient_session.reload.strict_loading!(false)
    stub_authorization(allowed: true)
  end

  context "without consent" do
    it { should_not have_content(/Consent (given|refused)/) }
    it { should_not have_css("details", text: /Consent (given|refused) by/) }
    it { should_not have_css("details", text: "Responses to health questions") }
    it { should have_css("p", text: "No requests have been sent.") }
    it { should have_css("button", text: "Get verbal consent") }

    context "when session is not in progress" do
      let(:session) { create(:session, :scheduled, programmes: [programme]) }

      it { should_not have_css("button", text: "Assess Gillick competence") }
    end
  end

  context "when vaccinated" do
    before do
      create(:patient_vaccination_status, :vaccinated, patient:, programme:)
    end

    it { should_not have_css("p", text: "No requests have been sent.") }
    it { should_not have_css("button", text: "Get verbal consent") }
    it { should_not have_css("button", text: "Assess Gillick competence") }
  end

  context "with refused consent" do
    let!(:consent) { create(:consent, :refused, patient:, programme:) }

    before { create(:patient_consent_status, :refused, patient:, programme:) }

    it { should have_css(".app-card--red", text: "Consent refused") }
    it { should have_css("tr", text: /#{consent.parent.full_name}/) }
    it { should have_css("tr", text: /#{consent.parent_relationship.label}/) }
    it { should have_css("table tr", text: /Consent refused/) }
    it { should_not have_css("details", text: "Responses to health questions") }
  end

  context "with given consent" do
    let!(:consent) { create(:consent, :given, patient:, programme:) }

    before { create(:patient_consent_status, :given, patient:, programme:) }

    it { should have_css(".app-card--aqua-green", text: "Consent given") }
    it { should_not have_css("a", text: "Contact #{consent.parent.full_name}") }
  end
end
