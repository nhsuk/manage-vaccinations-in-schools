# frozen_string_literal: true

describe AppSubNavigationComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new.tap do |nav|
      nav.with_item(selected: true, href: "https://example.com") { "Example 1" }
      nav.with_item(
        selected: false,
        text: "Example 2",
        href: "https://example.com"
      )
    end
  end

  it { should have_css("nav.app-sub-navigation") }

  it { should have_css("ul.app-sub-navigation__section") }
  it { should have_css("li.app-sub-navigation__section-item") }

  it { should have_css(".app-sub-navigation__section-item--current").once }

  it { should have_link("Example 1", href: "https://example.com") }
  it { should have_link("Example 2", href: "https://example.com") }
end
