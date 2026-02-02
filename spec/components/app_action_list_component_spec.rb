# frozen_string_literal: true

describe AppActionListComponent do
  subject { render_inline(component) }

  let(:component) do
    described_class.new.tap do |action_list|
      action_list.with_item { "Example 1" }
      action_list.with_item(href: "https://example.com") { "Example 2" }
      action_list.with_item(text: "Example 3", href: "https://example.com")
    end
  end

  it { should have_css("ul.app-action-list") }

  it { should have_css("li.app-action-list__item").exactly(3).times }

  it { should have_text("Example 1") }
  it { should have_link("Example 2", href: "https://example.com") }
  it { should have_link("Example 3", href: "https://example.com") }
end
