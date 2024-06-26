# frozen_string_literal: true

require "rails_helper"

describe AppDevToolsComponent, type: :component do
  subject(:rendered) { render_inline(component) { body } }

  let(:consent) { create(:consent, :refused, :from_dad, parent_name: "Harry") }
  let(:consents) { [consent] }
  let(:component) { described_class.new }
  let(:body) { "Hello dev tools!" }

  it "renders in development" do
    allow(Rails).to receive(:env).and_return("development".inquiry)
    expect(rendered.to_html).to include("Hello dev tools!")
  end

  it "does not render in production" do
    allow(Rails).to receive(:env).and_return("production".inquiry)
    expect(rendered.to_html).to be_blank
  end
end
