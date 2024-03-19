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
    should have_css("div", text: /Response(.*?)Consent refused/m)
  end

  it "displays only the refusal reason if there are no notes" do
    should have_css("div", text: /Refusal reason ?Personal choice/)
  end

  context "with a refusal reason with notes" do
    let(:consent) do
      create(
        :consent,
        :refused,
        reason_for_refusal: :already_vaccinated,
        reason_for_refusal_notes: "Had it at the GP"
      )
    end

    it "displays both the refusal reason and notes" do
      should have_css(
               "div",
               text:
                 /Refusal reason ?Vaccine already received ?Had it at the GP/
             )
    end
  end
end
