# frozen_string_literal: true

require "rails_helper"

describe AppEmptyListComponent, type: :component do
  subject { page }
  let(:component) { described_class.new(title:) }
  before { render_inline(component) }

  context "when no title is provided" do
    let(:component) { described_class.new }

    it { should have_css(".nhsuk-body", text: "No results") }
  end

  context "when a title is provided" do
    let(:title) { "Some other title" }

    it { should have_css(".nhsuk-heading-s", text: "Some other title") }
  end
end
