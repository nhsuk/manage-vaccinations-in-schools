require "rails_helper"

RSpec.describe AppEmptyListComponent, type: :component do
  let(:component) { described_class.new(title:) }
  before { render_inline(component) }

  subject { page }

  context "when no title is provided" do
    let(:title) { {} }

    it { should have_css(".nhsuk-body", text: "No results") }
  end

  context "when a title is provided" do
    let(:title) { "No results" }

    it { should have_css(".nhsuk-heading-s", text: "No results") }
  end
end
