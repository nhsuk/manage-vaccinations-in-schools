require "rails_helper"

RSpec.describe AppConsentComponent, type: :component do
  before { rendered_component }

  subject { page }

  let(:component) do
    described_class.new(patient_session:, section: "triage", tab: "needed")
  end
  let(:rendered_component) { render_inline(component) }

  let(:consent) { patient_session.consents.first }
  let(:relation) { consent.human_enum_name(:parent_relationship).capitalize }

  context "consent is not present" do
    let(:patient_session) { create(:patient_session) }

    it { should_not have_css("p.app-status", text: "Consent (given|refused)") }
    it { should_not have_css("details", text: /Consent (given|refused) by/) }
    it { should_not have_css("details", text: "Responses to health questions") }
    it { should have_css("p", text: "No response yet") }
    it { should have_css("button", text: "Get consent") }
    it { should have_css("button", text: "Assess Gillick competence") }
  end

  context "consent is not present and session is not in progress" do
    let(:patient_session) do
      create(:patient_session, session: create(:session, :in_future))
    end

    it { should_not have_css("button", text: "Assess Gillick competence") }
  end

  context "consent is refused" do
    let(:patient_session) { create(:patient_session, :consent_refused) }

    it { should have_css("p.app-status", text: "Consent refused") }

    let(:summary) { "Consent refused by #{consent.parent_name} (#{relation})" }
    it { should have_css("details[open]", text: summary) }
    it { should have_css("div", text: /Name ?#{consent.parent_name}/) }
    it { should have_css("div", text: /Relationship ?#{relation}/) }

    it "displays the parents phone and email" do
      should have_css(
               "div",
               text: /Contact ?#{consent.parent_phone} ?#{consent.parent_email}/
             )
    end

    it "displays the response" do
      should have_css("div", text: /Response(.*?)Consent refused/m)
    end

    it "displays only the refusal reason if there are no notes" do
      should have_css("div", text: /Refusal reason ?Personal choice/)
    end

    it do
      should have_css(
               "a",
               text: "Contact #{consent.parent_name} (the parent who refused)"
             )
    end
    it { should_not have_css("details", text: "Responses to health questions") }
  end

  context "consent is given" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed)
    end

    it { should have_css("p.app-status", text: "Consent given") }

    let(:summary) { "Consent given by #{consent.parent_name} (#{relation})" }
    it { should have_css("details[open]", text: summary) }

    it { should_not have_css("a", text: "Contact #{consent.parent_name}") }
  end

  context "consent given needing triage and patient has been vaccinated" do
    let(:patient_session) { create(:patient_session, :vaccinated) }

    let(:summary) { "Consent given by #{consent.parent_name} (#{relation})" }
    it { should have_css("details:not([open])", text: summary) }
  end

  context "consent given needing triage and patient cannot be vaccinated" do
    let(:patient_session) do
      create(:patient_session, :triaged_do_not_vaccinate)
    end

    let(:summary) { "Consent given by #{consent.parent_name} (#{relation})" }
    it { should have_css("details:not([open])", text: summary) }
  end
end
