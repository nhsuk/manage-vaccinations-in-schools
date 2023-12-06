require "rails_helper"

RSpec.describe AppPatientPageComponent, type: :component do
  let(:patient_session) do
    FactoryBot.create(
      :patient_session,
      :triaged_ready_to_vaccinate,
      :session_in_progress
    )
  end
  let(:component) { described_class.new(patient_session:, route: "triage") }

  describe "rendering" do
    before { render_inline(component) }

    subject { page }

    it { should have_css(".nhsuk-card", text: "Child details") }
    it { should have_css(".nhsuk-card", text: "Consent") }
    it { should have_css(".nhsuk-card", text: "Triage notes") }
    it { should have_css(".nhsuk-card", text: "Did they get the HPV vaccine?") }
  end
end
