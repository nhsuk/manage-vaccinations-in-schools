require "rails_helper"

RSpec.describe AppGillickCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent_response:, patient_session:) }
  let(:consent_response) { create(:consent_response) }
  let(:patient_session) { create(:patient_session, gillick_competent:) }
  let(:gillick_competent) { true }

  context "when patient is gillick competent" do
    it { should have_css("h2", text: "Gillick competence") }
    it { should have_css("dd", text: "Yes") }
  end

  context "when patient is not gillick competent" do
    let(:gillick_competent) { false }

    it { should have_css("dd", text: "No") }
  end
end
