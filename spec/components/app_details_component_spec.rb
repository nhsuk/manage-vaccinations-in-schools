require "rails_helper"

RSpec.describe AppDetailsComponent, type: :component do
  let(:summary) { "A summary" }
  let(:content) { "A content" }
  let(:component) { described_class.new(summary:) }

  subject { page }

  before { render_inline(component) { content } }

  it { should have_css(".nhsuk-details") }
  it { should have_css(".nhsuk-details__summary", text: "A summary") }

  it "defaults to being closed" do
    should have_css(".nhsuk-details__text", text: "A content", visible: false)
  end

  context "open flag is true" do
    let(:component) { described_class.new(summary:, open: true) }

    it "displays the content section" do
      should have_css(".nhsuk-details__text", text: "A content", visible: true)
    end
  end
end
