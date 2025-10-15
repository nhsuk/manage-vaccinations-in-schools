# frozen_string_literal: true

describe AppAttachedTagsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(items) }

  let(:items) do
    {
      "MenACWY" => {
        text: "Consent given",
        colour: "green"
      },
      "Td/IPV" => {
        text: "Consent refused",
        colour: "red",
        details_text: "Did not consent"
      }
    }
  end

  it { should have_content("MenACWYConsent given") }
  it { should have_content("Td/IPVConsent refusedDid not consent") }
end
