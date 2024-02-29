require "rails_helper"

RSpec.describe AppGillickCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(consent:, patient_session:) }
  let(:consent) { create(:consent) }
  let(:assessing_nurse) { create(:user, full_name: "Nurse Joy") }
  let(:patient_session) do
    create(
      :patient_session,
      :after_gillick_competence_assessed,
      gillick_competent:,
      gillick_competence_assessor: assessing_nurse
    )
  end
  let(:gillick_competent) { true }

  it { should have_text("Nurse Joy") }

  context "when patient is gillick competent" do
    it { should have_css("h2", text: "Gillick competence") }
    it { should have_css("dd", text: "Yes") }
  end

  context "when patient is not gillick competent" do
    let(:gillick_competent) { false }

    it { should have_css("dd", text: "No") }
  end
end
