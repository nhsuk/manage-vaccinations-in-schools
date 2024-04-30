require "rails_helper"

RSpec.describe AppCardComponent, type: :component do
  let(:heading) { "A Heading" }
  let(:body) { "A Body" }
  let(:component) { described_class.new(heading:) }

  subject { page }

  before { render_inline(component) { body } }

  it { should have_css(".nhsuk-card") }
  it { should have_css("h2.nhsuk-card__heading", text: heading) }
  it { should have_css(".nhsuk-card__content", text: "A Body") }

  context "no content is provided" do
    let(:body) { nil }

    it { should_not have_css(".nhsuk-card__content") }
  end

  context "classes on container" do
    let(:component) do
      described_class.new(heading:, card_classes: "app-card--empty")
    end

    it { should have_css(".nhsuk-card.app-card--empty") }
  end

  context "larger heading" do
    let(:component) { described_class.new(heading:, heading_size: "xl") }

    it { should have_css("h2.nhsuk-heading-xl", text: heading) }
  end

  context "feature card" do
    let(:component) { described_class.new(heading:, feature: true) }

    describe "card_classes" do
      subject { component.send(:card_classes) }

      it { should include "nhsuk-card--feature" }
    end

    describe "content_classes" do
      subject { component.send(:content_classes) }

      it { should include "nhsuk-card__content--feature" }
    end

    describe "heading_classes" do
      subject { component.send(:heading_classes) }

      it { should include "nhsuk-card__heading--feature" }
    end
  end

  context "coloured card" do
    let(:component) { described_class.new(heading:, colour: "purple") }

    describe "card_classes" do
      subject { component.send(:card_classes) }

      it { should include "app-card--purple" }
    end
  end

  context "link_to is specified" do
    let(:component) do
      described_class.new(heading:, link_to: "http://example.com")
    end

    describe "card_classes" do
      subject { component.send(:card_classes) }

      it { should include "nhsuk-card--clickable" }
    end

    it { is_expected.to have_link(href: "http://example.com") }
  end
end
