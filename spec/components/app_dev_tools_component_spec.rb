# frozen_string_literal: true

require "rails_helper"

describe AppDevToolsComponent, type: :component do
  subject { page }
  let(:consent) { create(:consent, :refused, :from_dad, parent_name: "Harry") }
  let(:consents) { [consent] }
  let(:component) { described_class.new }
  let!(:rendered) { render_inline(component) { body } }
  let(:body) { "Hello dev tools!" }

  it "renders in development" do
    allow(Rails).to receive(:env).and_return("development".inquiry)
    expect(render_inline(component).to_html).to include("Hello dev tools!")
  end

  it "does not render in production" do
    allow(Rails).to receive(:env).and_return("production".inquiry)
    expect(render_inline(component).to_html).to be_blank
  end
end
