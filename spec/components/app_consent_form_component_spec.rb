require "rails_helper"

RSpec.describe AppConsentFormComponent, type: :component do
  let(:consent_form) do
    create :consent_form, :recorded, parent_relationship: :father
  end
  let(:component) { described_class.new(consent_form:) }

  subject { page }

  before { render_inline(component) }

  it { should have_css("div", text: /Name ?#{consent_form.parent_name}/) }
  it { should have_css("div", text: /Relationship ?Dad/) }

  it "displays the parents phone and email" do
    should have_css(
             "div",
             text:
               /Contact ?#{consent_form.parent_phone} ?#{consent_form.parent_email}/
           )
  end

  it "displays the response given" do
    should have_css("div", text: /Response(.*?)Consent given/m)
  end

  context "with a refusal reason wihout notes" do
    let(:consent_form) do
      create :consent_form, :recorded, :refused, reason: :personal_choice
    end

    it "displays only the refusal reason" do
      should have_css("div", text: /Refusal reason ?Personal choice/)
    end
  end

  context "with a refusal reason with notes" do
    let(:consent_form) do
      create :consent_form,
             :recorded,
             :refused,
             reason: :already_vaccinated,
             reason_notes: "Already had the vaccine at the GP"
    end

    it "displays the refusal reason and notes" do
      should have_css(
               "div",
               text:
                 /Refusal reason ?Vaccine already received ?Already had the vaccine at the GP/
             )
    end
  end
end
