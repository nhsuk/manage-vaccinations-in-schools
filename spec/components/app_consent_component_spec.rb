require "rails_helper"

RSpec.describe AppConsentComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(patient_session:, consent:, route:) }
  let(:patient_session) { create(:patient_session) }
  let(:consent) { create(:consent, patient_session:) }
  let(:route) { "triage" }

  context "when consent is present" do
    it { should have_css("dd", text: consent.who_responded.capitalize) }
    it { should have_css("dd", text: consent.parent_name) }
    it { should have_css("dd", text: consent.created_at.to_fs(:nhsuk_date)) }
    it { should have_css("dd", text: "Website") }
    it { should have_css("details", text: "Responses to health questions") }
  end

  context "when consent is refused" do
    let(:consent) { create(:consent_refused) }

    it { should have_css("dt", text: "Reason for refusal") }
    it { should have_css("dd", text: "Personal choice") }
    it { should_not have_css("details", text: "Responses to health questions") }
  end

  context "when consent is not present" do
    let(:consent) { nil }

    it { should have_css("p", text: "No response yet") }
    it { should have_css("a", text: "Get consent") }
  end
end
