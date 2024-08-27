# frozen_string_literal: true

describe AppBreadcrumbComponent, type: :component do
  subject { page }

  before { render_inline(component) }

  let(:component) { described_class.new(items:, classes:, attributes:) }

  # in the app, we set the current page as plain text and the previous page as a link
  let(:items) do
    [
      { href: "/previous-page", text: "Previous page" },
      { text: "Current page" }
    ]
  end
  let(:classes) { "additional-class" }
  let(:attributes) { { id: "breadcrumb" } }

  it { should have_link("Previous page", href: "/previous-page") }
  it { should have_text("Current page") }
  it { should have_css("nav.additional-class") }

  it "renders a back link on narrow viewports" do
    expect(page).to have_link(
      "Previous page",
      href: "/previous-page",
      class: "nhsuk-breadcrumb__backlink"
    )
  end
end
