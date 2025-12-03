# frozen_string_literal: true

describe AppSecondaryNavigationComponent do
  subject(:rendered) { render_inline(component) }

  let(:reverse) { false }

  let(:component) do
    described_class
      .new(reverse:)
      .tap do |nav|
        nav.with_item(selected: true, href: "https://example.com") do
          "Example 1"
        end
        nav.with_item(
          selected: false,
          text: "Example 2",
          href: "https://example.com",
          ticked: true
        )
      end
  end

  it { should have_css("nav.app-secondary-navigation") }

  it { should have_css("ul.app-secondary-navigation__list") }
  it { should have_css("li.app-secondary-navigation__list-item") }

  it { should have_css("strong.app-secondary-navigation__current").once }
  it { should have_css(".nhsuk-icon").once }

  it { should have_link("Example 1", href: "https://example.com") }
  it { should have_link("Example 2", href: "https://example.com") }

  context "with reverse styles" do
    let(:reverse) { true }

    it do
      expect(rendered).to have_css(
        "nav.app-secondary-navigation.app-secondary-navigation--reverse"
      )
    end
  end
end
