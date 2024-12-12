# frozen_string_literal: true

describe AppCardComponent do
  context "with a title" do
    subject(:rendered) do
      render_inline(described_class.new) { _1.with_heading { "Test" } }
    end

    it { should have_css("h2.nhsuk-heading-m", text: "Test") }
  end

  context "with a description" do
    subject(:rendered) do
      render_inline(described_class.new) { _1.with_description { "Test" } }
    end

    it { should have_css("p.nhsuk-card__description", text: "Test") }
  end

  context "with a link" do
    subject(:rendered) do
      render_inline(described_class.new(link_to: "foo")) do
        _1.with_heading { "Test" }
      end
    end

    it { should have_css(".nhsuk-card--clickable") }
    it { should have_link(href: "foo") }
  end

  context "with a colour" do
    subject(:rendered) { render_inline(described_class.new(colour: "red")) }

    it { should have_css(".nhsuk-card--feature") }
    it { should have_css(".app-card--red") }
  end

  context "when secondary" do
    subject(:rendered) { render_inline(described_class.new(secondary: true)) }

    it { should have_css(".nhsuk-card--secondary") }
  end
end
