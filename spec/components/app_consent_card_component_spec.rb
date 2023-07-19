require "rails_helper"

RSpec.describe AppConsentCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent_response:, patient:, session:) }
  let(:consent_response) { create(:consent_response) }
  let(:patient) { create(:patient) }
  let(:session) { create(:session) }

  context "when consent is present" do
    it { should have_css("h2", text: "Consent") }
    it { should have_css("dd", text: consent_response.who_responded.capitalize) }
    it { should have_css("dd", text: consent_response.parent_name) }
    it { should have_css("dd", text: consent_response.created_at.to_fs(:nhsuk_date)) }
    it { should have_css("dd", text: ConsentResponse
      .human_enum_name("route",
                       consent_response.route)) }
  end

  context "when consent is refused" do
    let(:consent_response) { create(:consent_response, :refused) }

    it { should have_css("dt", text: "Reason for refusal") }
    it { should have_css("dd", text: ConsentResponse
      .human_enum_name("reason_for_refusal",
                       consent_response.reason_for_refusal)) }
  end

  context "when consent is not present" do
    let(:consent_response) { nil }

    it { should have_css("p", text: "No response given") }
    it { should have_css("a", text: "Get consent") }
  end
end
