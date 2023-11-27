require "rails_helper"

RSpec.describe AppPatientPageComponent, type: :component do
  let(:patient_session) { FactoryBot.create(:patient_session) }
  let(:consent) { nil }
  let(:component) do
    described_class.new(
      patient_session:,
      consent:,
      route: "triage"
    )
  end

  describe "rendering" do
    before { render_inline(component) }

    subject { page }

    it { should have_css(".nhsuk-card", text: "Child details") }

    context "with consent object" do
      let(:consent) { FactoryBot.create(:consent, patient_session:) }
      it { should have_css(".nhsuk-card", text: "Consent") }
    end

    context "with no consent object" do
      let(:consent) { nil }
      it { should_not have_css(".nhsuk-card", text: "Consent") }
    end
  end
end
