# frozen_string_literal: true

describe AppCardComponent::Heading do
  let(:content) { "Test Heading" }

  context "with default parameters" do
    subject(:rendered) { render_inline(described_class.new) { content } }

    it do
      expect(rendered).to have_css(
        "h3.nhsuk-card__heading.nhsuk-heading-m",
        text: content
      )
    end

    it { should_not have_css("div.nhsuk-card__heading-container") }
  end

  context "with level 1" do
    subject { render_inline(described_class.new(level: 1)) { content } }

    it { should have_css("h1.nhsuk-heading-m") }
  end

  context "with level 2" do
    subject { render_inline(described_class.new(level: 2)) { content } }

    it { should have_css("h2.nhsuk-heading-m") }
  end

  context "with level 4" do
    subject { render_inline(described_class.new(level: 4)) { content } }

    it { should have_css("h4.nhsuk-heading-s") }
  end

  context "with level 5" do
    subject { render_inline(described_class.new(level: 5)) { content } }

    it { should have_css("h5.nhsuk-heading-s") }
  end

  context "with explicit size" do
    subject do
      render_inline(described_class.new(size: "xl", level: 4)) { content }
    end

    it { should have_css("h4.nhsuk-heading-xl") }
  end

  context "with small size" do
    subject { render_inline(described_class.new(size: "s")) { content } }

    it { should have_css("h3.nhsuk-heading-s") }
  end

  context "with large size" do
    subject { render_inline(described_class.new(size: "l")) { content } }

    it { should have_css("h3.nhsuk-heading-l") }
  end

  context "with a colour" do
    subject { render_inline(described_class.new(colour: "blue")) { content } }

    it { should have_css(".app-card__heading--blue") }
  end

  context "with a link" do
    subject { render_inline(described_class.new(link_to: "#")) { content } }

    it { should have_link(href: "#") }
    it { should have_css("h3 > a.nhsuk-card__link") }
  end

  context "without a link" do
    subject { render_inline(described_class.new(link_to: nil)) { content } }

    it { should_not have_css("a") }
  end

  context "with empty link" do
    subject { render_inline(described_class.new(link_to: "")) { content } }

    it { should_not have_css("a") }
  end

  context "without actions" do
    subject { render_inline(described_class.new) { content } }

    it { should_not have_css("ul.nhsuk-card__actions") }
  end

  context "with actions" do
    subject do
      render_inline(
        described_class.new(
          actions: [
            { text: "Edit", href: "/edit" },
            { text: "Delete", href: "/delete" }
          ]
        )
      ) { content }
    end

    it { should have_css("div.nhsuk-card__heading-container") }
    it { should have_css("ul.nhsuk-card__actions") }
    it { should have_css("li.nhsuk-card__action", count: 2) }
    it { should have_link("Edit", href: "/edit", class: "nhsuk-link") }
    it { should have_link("Delete", href: "/delete", class: "nhsuk-link") }
  end

  context "with empty actions array" do
    subject { render_inline(described_class.new(actions: [])) { content } }

    it { should_not have_css("ul.nhsuk-card__actions") }
  end

  context "with all parameters" do
    subject(:rendered) do
      render_inline(
        described_class.new(
          level: 2,
          size: "l",
          colour: "green",
          link_to: "#",
          actions: [{ text: "Edit", href: "/edit" }]
        )
      ) { content }
    end

    it do
      expect(rendered).to have_css(
        "h2.nhsuk-card__heading.nhsuk-heading-l.app-card__heading--green"
      )
    end

    it { should have_link(href: "#") }

    it { should have_css("ul.nhsuk-card__actions") }
    it { should have_link("Edit", href: "/edit", class: "nhsuk-link") }
  end
end
