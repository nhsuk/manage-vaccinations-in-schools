# frozen_string_literal: true

describe AppCardComponent do
  subject { render_inline(described_class.new) }

  it { should have_css("div.nhsuk-card") }

  context "with a title" do
    subject do
      render_inline(described_class.new) { it.with_heading { "Test" } }
    end

    it { should have_css("h3.nhsuk-heading-m", text: "Test") }
  end

  context "with a description" do
    subject do
      render_inline(described_class.new) { it.with_description { "Test" } }
    end

    it { should have_css("p.nhsuk-card__description", text: "Test") }
  end

  context "with a link" do
    subject do
      render_inline(described_class.new(link_to: "foo")) do
        it.with_heading { "Test" }
      end
    end

    it { should have_css(".nhsuk-card--clickable") }
    it { should have_link(href: "foo") }
  end

  context "with a colour" do
    subject { render_inline(described_class.new(colour: "red")) }

    it { should have_css(".nhsuk-card--feature") }
    it { should have_css(".app-card--red") }
  end

  context "when secondary" do
    subject { render_inline(described_class.new(secondary: true)) }

    it { should have_css(".nhsuk-card--secondary") }
  end

  context "when a section" do
    subject { render_inline(described_class.new(section: true)) }

    it { should have_css("section.nhsuk-card") }
  end
end
