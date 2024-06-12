require "rails_helper"

describe Card, type: :phlex_component do
  let(:component) { described_class.new }

  subject { render component }

  it { should have_css(".nhsuk-card") }

  context "with a title" do
    let(:component) { described_class.new { _1.title { "Test" } } }

    it { should have_css("h2.nhsuk-heading-m", text: "Test") }
  end

  context "with a large title" do
    let(:component) { described_class.new { _1.title(size: "l") { "Test" } } }

    it { should have_css("h2.nhsuk-heading-l", text: "Test") }
  end

  context "with a description" do
    let(:component) { described_class.new { _1.description { "Test" } } }

    it { should have_css("p.nhsuk-card__description", text: "Test") }
  end

  context "with a link" do
    let(:component) do
      described_class.new(link_to: "foo") { _1.title { "Test" } }
    end

    it { should have_css(".nhsuk-card--clickable") }
    it { should have_link(href: "foo") }
  end

  context "with a colour" do
    let(:component) { described_class.new(colour: "red") }

    it { should have_css(".nhsuk-card--feature") }
    it { should have_css(".app-card--red") }
  end
end
