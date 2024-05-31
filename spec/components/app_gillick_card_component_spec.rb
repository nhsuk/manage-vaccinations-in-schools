require "rails_helper"

RSpec.describe AppGillickCardComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(assessment:) }
  let(:assessor) { create(:user, full_name: "Nurse Joy") }
  let(:assessment) do
    create(
      :gillick_assessment,
      gillick_competent:,
      notes: "This is a note",
      assessor:
    )
  end
  let(:gillick_competent) { true }

  it { should have_text("Nurse Joy") }

  context "when patient is Gillick competent" do
    it { should have_css("h2", text: "Gillick competence") }
    it { should have_css("dd", text: "Yes") }
  end

  context "when patient is not Gillick competent" do
    let(:gillick_competent) { false }

    it { should have_css("dd", text: "No") }
  end
end
