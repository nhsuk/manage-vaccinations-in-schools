# frozen_string_literal: true

require "rails_helper"

describe AppDetailsComponent, type: :component do
  subject { page }
  let(:summary) { "A summary" }
  let(:content) { "A content" }
  let(:component) { described_class.new(summary:) }

  before { render_inline(component) { content } }

  it { should have_css(".nhsuk-details") }
  it { should have_css(".nhsuk-details__summary", text: summary) }

  it "defaults to being closed" do
    should have_css(".nhsuk-details__text", text: content, visible: false)
  end

  context "open flag is true" do
    let(:component) { described_class.new(summary:, open: true) }

    it "displays the content section" do
      should have_css(".nhsuk-details__text", text: content, visible: true)
    end
  end
end
