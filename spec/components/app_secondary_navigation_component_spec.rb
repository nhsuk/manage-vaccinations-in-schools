# frozen_string_literal: true

require "rails_helper"
require "govuk_helper"

describe AppSecondaryNavigationComponent, type: :component do
  subject { rendered_content }

  before { render_inline(component) }

  let(:component) do
    described_class.new.tap do |nav|
      nav.with_item(selected: true, href: "https://example.com") { "Example 1" }
      nav.with_item(selected: false, href: "https://example.com") do
        "Example 2"
      end
    end
  end

  it { should have_tag("nav", with: { class: "app-secondary-navigation" }) }
  it do
    expect(subject).to have_tag(
      "ul",
      with: {
        class: "app-secondary-navigation__list"
      }
    )
  end
  it do
    expect(subject).to have_tag(
      "li",
      with: {
        class: "app-secondary-navigation__list-item"
      }
    )
  end
  it do
    expect(subject).to have_tag(
      "li",
      with: {
        class: "app-secondary-navigation__list-item--current"
      }
    )
  end
  it { should have_link("Example 1", href: "https://example.com") }
end
