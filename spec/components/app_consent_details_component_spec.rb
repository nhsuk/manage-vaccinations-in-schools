require "rails_helper"

RSpec.describe AppConsentDetailsComponent, type: :component do
  let(:consent) { create(:consent, :refused, :from_dad, parent_name: "Harry") }
  let(:consents) { [consent] }
  let(:component) { described_class.new(consents:) }

  subject { page }

  before { render_inline(component) }

  it { should have_css("div", text: /Name ?Harry/) }
  it { should have_css("div", text: /Relationship ?Dad/) }

  it "displays the parents phone and email" do
    should have_css(
             "div",
             text: /Contact ?#{consent.parent_phone} ?#{consent.parent_email}/
           )
  end

  it "displays the response given" do
    should have_css("div", text: /Response ?Consent refused/)
  end

  it "displays the refusal reason" do
    should have_css("div", text: /Refusal reason ?Personal choice/)
  end
end
