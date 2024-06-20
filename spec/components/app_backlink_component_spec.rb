require "rails_helper"

describe AppBacklinkComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(href:, name:, classes:, attributes:) }
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
end
