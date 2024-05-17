require "rails_helper"

RSpec.describe AppConsentStatusComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(patient_session:) }
  let(:patient_session) { create(:patient_session) }

  context "when consent is given" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed)
    end

    it { should have_css("p.app-status", text: "Given") }
  end

  context "when consent is refused" do
    let(:patient_session) { create(:patient_session, :consent_refused) }

    it { should have_css("p.app-status", text: "Refused") }
  end

  context "when consent conflicts" do
    let(:patient_session) { create(:patient_session, :consent_conflicting) }

    it { should have_css("p.app-status", text: "Conflicts") }
  end
end
