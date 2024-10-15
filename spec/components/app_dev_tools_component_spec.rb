# frozen_string_literal: true

describe AppDevToolsComponent, type: :component do
  subject(:rendered) { render_inline(component) { body } }

  let(:consent) do
    create(:consent, :refused, :from_dad, parent_full_name: "Harry")
  end
  let(:consents) { [consent] }
  let(:component) { described_class.new }
  let(:body) { "Hello dev tools!" }

  it "renders in development when the feature flag is enabled" do
    allow(Rails).to receive(:env).and_return("development".inquiry)
    allow(Flipper).to receive(:enabled?).with(:dev_tools).and_return(true)
    expect(rendered.to_html).to include("Hello dev tools!")
  end

  it "does not render in production" do
    allow(Rails).to receive(:env).and_return("production".inquiry)
    allow(Flipper).to receive(:enabled?).with(:dev_tools).and_return(true)
    expect(rendered.to_html).to be_blank
  end

  it "does not render in development when the feature flag is turned off" do
    allow(Rails).to receive(:env).and_return("development".inquiry)
    allow(Flipper).to receive(:enabled?).with(:dev_tools).and_return(false)
    expect(rendered.to_html).to be_blank
  end
end
