# frozen_string_literal: true

require "rails_helper"
require "govuk_helper"

describe AppSecondaryNavigationComponent, type: :component do
  before { render_inline(component) }

  subject { rendered_content }

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
    should have_tag("ul", with: { class: "app-secondary-navigation__list" })
  end
  it do
    should have_tag(
             "li",
             with: {
               class: "app-secondary-navigation__list-item"
             }
           )
  end
  it do
    should have_tag(
             "li",
             with: {
               class: "app-secondary-navigation__list-item--current"
             }
           )
  end
  it do
    should have_tag("a", with: { href: "https://example.com" }) do
      with_text("Example 1")
    end
  end
end
