require "rails_helper"

RSpec.describe AppGillickCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent_response:, patient:, session:) }
  let(:consent_response) do
    create(:consent_response,
           campaign: session.campaign,
           patient:,
           route: 'self_consent',
           consent:)
  end
  let(:patient) { session.patients.first }
  let(:session) { create(:session) }
  let(:consent) { "given" }

  context "when patient is gillick competent" do
    it { should have_css("h2", text: "Gillick competence") }
    it { should have_css("dd", text: "Yes") }
  end

  context "when patient is not gillick competent" do
    let(:consent) { "not_provided" }

    it { should have_css("dd", text: "No") }
  end
end
