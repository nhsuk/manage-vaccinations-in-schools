# frozen_string_literal: true

describe AppSecondaryNavigationComponent do
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

  it { should have_css("nav.app-secondary-navigation") }

  it { should have_css("ul.app-secondary-navigation__list") }
  it { should have_css("li.app-secondary-navigation__list-item") }
  it { should have_css("strong.app-secondary-navigation__current") }

  it { should have_link("Example 1", href: "https://example.com") }
  it { should have_link("Example 2", href: "https://example.com") }
end
