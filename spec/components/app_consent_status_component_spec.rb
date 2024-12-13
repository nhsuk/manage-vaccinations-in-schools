# frozen_string_literal: true

describe AppConsentStatusComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_session:) }
  let(:patient_session) { create(:patient_session) }

  context "when consent is given" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed)
    end

    it { should have_css("p.app-status--aqua-green", text: "Consent given") }
  end

  context "when consent is refused" do
    let(:patient_session) { create(:patient_session, :consent_refused) }

    it { should have_css("p.app-status--red", text: "Consent refused") }
  end

  context "when consent conflicts" do
    let(:patient_session) { create(:patient_session, :consent_conflicting) }

    it do
      expect(rendered).to have_css(
        "p.app-status--dark-orange",
        text: "Conflicting consent"
      )
    end
  end
end
