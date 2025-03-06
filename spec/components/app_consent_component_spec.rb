# frozen_string_literal: true

describe AppConsentComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(patient_session:, programme: programmes.first)
  end

  let(:programmes) { [create(:programme)] }
  let(:consent) { patient_session.consent.all[programmes.first].first }

  before { patient_session.reload.strict_loading!(false) }

  context "consent is not present" do
    let(:patient_session) { create(:patient_session, programmes:) }

    it { should_not have_css("p.app-status", text: "Consent (given|refused)") }
    it { should_not have_css("details", text: /Consent (given|refused) by/) }
    it { should_not have_css("details", text: "Responses to health questions") }
    it { should have_css("p", text: "No requests have been sent.") }
    it { should have_css("button", text: "Get consent") }
  end

  context "consent is not present and session is not in progress" do
    let(:session) { create(:session, :scheduled, programmes:) }
    let(:patient_session) { create(:patient_session, session:, programmes:) }

    it { should_not have_css("button", text: "Assess Gillick competence") }
  end

  context "consent is refused" do
    let(:patient_session) do
      create(:patient_session, :consent_refused, programmes:)
    end

    it { should have_css("p.app-status--red", text: "Consent refused") }

    it { should have_css("table tr", text: /#{consent.parent.full_name}/) }

    it do
      expect(rendered).to have_css(
        "table tr",
        text: /#{consent.parent_relationship.label}/
      )
    end

    it "displays the response" do
      expect(rendered).to have_css("table tr", text: /Consent refused/)
    end

    it { should_not have_css("details", text: "Responses to health questions") }
  end

  context "consent is given" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed, programmes:)
    end

    it { should have_css("p.app-status--aqua-green", text: "Consent given") }
    it { should_not have_css("a", text: "Contact #{consent.parent.full_name}") }
  end
end
