# frozen_string_literal: true

describe AppBreadcrumbComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(items:, attributes:) }

  # in the app, we set the current page as plain text and the previous page as a link
  let(:items) do
    [
      { href: "/previous-page", text: "Previous page" },
      { text: "Current page" }
    ]
  end
  let(:attributes) { { id: "breadcrumb" } }

  it { should have_link("Previous page", href: "/previous-page") }
  it { should have_text("Current page") }

  it "renders a back link on narrow viewports" do
    expect(rendered).to have_link(
      "Previous page",
      href: "/previous-page",
      class: "nhsuk-back-link"
    )
  end
end
