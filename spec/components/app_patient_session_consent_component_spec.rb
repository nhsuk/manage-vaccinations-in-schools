# frozen_string_literal: true

describe AppPatientSessionConsentComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient:, session:, programme:) }

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  before { stub_authorization(allowed: true) }

  context "without consent" do
    it { should_not have_content(/Consent (given|refused)/) }
    it { should_not have_css("details", text: /Consent (given|refused) by/) }
    it { should_not have_css("details", text: "Responses to health questions") }
    it { should have_css("p", text: "No requests have been sent.") }
    it { should have_css("button", text: "Record a new consent response") }

    context "when session is not in progress" do
      let(:session) { create(:session, :scheduled, programmes: [programme]) }

      it { should_not have_css("button", text: "Assess Gillick competence") }
    end
  end

  context "when vaccinated" do
    before do
      create(:patient_vaccination_status, :vaccinated, patient:, programme:)
    end

    it { should_not have_css("p", text: "No requests have been sent.") }
    it { should_not have_css("button", text: "Record a new consent response") }
    it { should_not have_css("button", text: "Assess Gillick competence") }
  end

  context "with refused consent" do
    let(:parent) { create(:parent_relationship, :mother, patient:).parent }
    let!(:consent) do
      create(:consent, :refused, patient: patient.reload, parent:, programme:)
    end

    before { create(:patient_consent_status, :refused, patient:, programme:) }

    it { should have_css(".app-card__heading--red", text: "Consent refused") }
    it { should have_content(consent.parent.full_name) }
    it { should have_content(consent.parent_relationship.label) }
    it { should have_content("Consent refused") }
    it { should_not have_css("details", text: "Responses to health questions") }
  end

  context "with given consent" do
    let(:patient) do
      create(:patient, :consent_given_triage_not_needed, session:)
    end

    let(:consent) { patient.consents.first }

    it do
      expect(rendered).to have_css(
        ".app-card__heading--aqua-green",
        text: "Consent given"
      )
    end

    it { should_not have_css("a", text: "Contact #{consent.parent.full_name}") }

    context "and the programme is flu" do
      let(:programme) { create(:programme, :flu) }

      let(:patient) do
        create(:patient, :consent_given_nasal_only_triage_not_needed, session:)
      end

      it { should have_text("Consent given for nasal spray") }

      context "and the vaccine method is overridden by triage" do
        let(:patient) do
          create(
            :patient,
            :consent_given_injection_and_nasal_triage_safe_to_vaccinate_injection,
            session:
          )
        end

        it { should have_text("Consent given for gelatine-free injection") }
      end
    end
  end
end
