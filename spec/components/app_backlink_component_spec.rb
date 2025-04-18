# frozen_string_literal: true

describe AppBacklinkComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(href, name:, classes:, attributes:) }
  let(:href) { "/previous_page" }
  let(:name) { "Previous Page" }
  let(:classes) { "additional-class" }
  let(:attributes) { { id: "back-link" } }

  it { should have_css(".nhsuk-back-link") }
  it { should have_css(".nhsuk-back-link__link") }
  it { should have_link(href:) }
  it { should have_css(".nhsuk-width-container.additional-class") }
  it { should have_css('[id="back-link"]') }
  it { should have_css(".nhsuk-u-visually-hidden", text: "to #{name}") }

  context "without a name" do
    let(:component) { described_class.new(href) }

    it { should have_css(".nhsuk-u-visually-hidden", text: "to previous page") }
  end
end
