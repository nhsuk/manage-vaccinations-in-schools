require "rails_helper"

RSpec.describe AppPatientPageComponent, type: :component do
  let(:triage) { [FactoryBot.create(:triage, notes: "Patient notes")] }
  let(:patient_session) { FactoryBot.create(:patient_session, triage:) }
  let(:consent) { FactoryBot.create(:consent, patient_session:) }
  let(:component) do
    described_class.new(patient_session:, consent:, route: "triage")
  end

  describe "rendering" do
    before { render_inline(component) }

    subject { page }

    it { should have_css(".nhsuk-card", text: "Child details") }
    it { should have_css(".nhsuk-card", text: "Consent") }
    it { should have_css(".nhsuk-card", text: "Triage notes") }
  end
end
