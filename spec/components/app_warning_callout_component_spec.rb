# frozen_string_literal: true

describe AppWarningCalloutComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(heading:, description:) }

  let(:heading) { "Heading" }
  let(:description) { "Description" }

  it { should have_css(".nhsuk-warning-callout") }
  it { should have_css(".nhsuk-u-visually-hidden", text: "Important:") }
  it { should have_css("h3.nhsuk-warning-callout__label", text: "Heading") }
  it { should have_css("p", text: "Description") }
end
