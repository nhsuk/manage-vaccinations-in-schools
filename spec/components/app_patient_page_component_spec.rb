require "rails_helper"

RSpec.describe AppPatientPageComponent, type: :component do
  let(:patient_session) { FactoryBot.create(:patient_session) }
  let(:component) { described_class.new(patient_session:) }

  describe "rendering" do
    before { render_inline(component) }

    subject { page }

    it { should have_css(".nhsuk-card", text: "Child details") }
  end
end
