# frozen_string_literal: true

describe AppConsentStatusComponent do
  subject(:rendered) { render_inline(component) }

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }

  let(:patient_session) { create(:patient_session, session:) }

  let(:component) { described_class.new(patient_session:, programme:) }

  before { patient_session.strict_loading!(false) }

  context "when consent is given" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed, session:)
    end

    it { should have_css("p.app-status--aqua-green", text: "Consent given") }
  end

  context "when consent is refused" do
    let(:patient_session) do
      create(:patient_session, :consent_refused, session:)
    end

    it { should have_css("p.app-status--red", text: "Consent refused") }
  end

  context "when consent conflicts" do
    let(:patient_session) do
      create(:patient_session, :consent_conflicting, session:)
    end

    it do
      expect(rendered).to have_css(
        "p.app-status--dark-orange",
        text: "Conflicting consent"
      )
    end
  end
end
