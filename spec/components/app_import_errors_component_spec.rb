# frozen_string_literal: true

describe AppImportErrorsComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(errors) }

  let(:errors) do
    [
      OpenStruct.new(attribute: :csv, type: :invalid),
      OpenStruct.new(attribute: :first_name, type: :blank),
      OpenStruct.new(attribute: :first_name, type: %i[invalid blank])
    ]
  end

  it { should have_text("CSV") }
  it { should have_text("First name") }

  it { should have_css("li", count: 4) }

  it { should have_text("blank") }
  it { should have_text("invalid") }
end
