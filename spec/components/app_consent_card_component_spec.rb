require "rails_helper"

RSpec.describe AppConsentCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent:, patient:, session:) }
  let(:consent) do
    create(:consent, campaign: session.campaign, patient:)
  end
  let(:patient) { session.patients.first }
  let(:session) { create(:session) }

  context "when consent is present" do
    it { should have_css("h2", text: "Consent") }
    it do
      should have_css("dd", text: consent.who_responded.capitalize)
    end
    it { should have_css("dd", text: consent.parent_name) }
    it do
      should have_css(
               "dd",
               text: consent.created_at.to_fs(:nhsuk_date)
             )
    end
    it { should have_css("dd", text: "Website") }
  end

  context "when consent is refused" do
    let(:consent) { create(:consent_refused) }

    it { should have_css("dt", text: "Reason for refusal") }
    it { should have_css("dd", text: "Personal choice") }
  end

  context "when consent is not present" do
    let(:consent) { nil }

    it { should have_css("p", text: "No response given") }
    it { should have_css("a", text: "Get consent") }
  end
end
