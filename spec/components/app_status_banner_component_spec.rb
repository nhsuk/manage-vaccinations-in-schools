require "rails_helper"

RSpec.describe AppStatusBannerComponent, type: :component do
  before { render_inline(component) }

  let(:patient_session) { create :patient_session }
  let(:component) { described_class.new(patient_session:) }

  subject { page }

  before do
    patient_session.patient.update!(first_name: "Alya", last_name: "Merton")
  end

  context "state is added_to_session" do
    let(:patient_session) { create :patient_session, :added_to_session }

    it { should have_css(".app-consent-banner--yellow") }
  end

  context "state is consent_given_triage_not_needed" do
    let(:patient_session) do
      create :patient_session, :consent_given_triage_not_needed
    end

    it { should have_css(".app-consent-banner--purple") }
    it { should have_text("Ready to vaccinate") }
    it "does not provide an explanation as no triage took place" do
      expect(component.explanation).to be_blank
    end
  end

  context "state is consent_given_triage_needed" do
    let(:patient_session) do
      create :patient_session, :consent_given_triage_needed
    end

    it { should have_css(".app-consent-banner--blue") }
    it { should have_text("Triage needed") }
  end

  context "state is consent_refused" do
    let(:patient_session) { create :patient_session, :consent_refused }

    it { should have_css(".app-consent-banner--orange") }
    it { should have_text("Their mum has refused to give consent") }
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) { create :patient_session, :triaged_do_not_vaccinate }

    it { should have_css(".app-consent-banner--red") }
    it { should have_text("Do not vaccinate") }
    it "explains who took the decision that the patient should not be vaccinated" do
      expect(component.explanation).to eq(
        "A nurse decided that Alya Merton should not be vaccinated."
      )
    end
  end

  context "state is triaged_kept_in_triage" do
    let(:patient_session) { create :patient_session, :triaged_kept_in_triage }

    it { should have_css(".app-consent-banner--aqua-green") }
    it { should have_text("Triage started") }
  end

  context "state is triaged_ready_to_vaccinate" do
    let(:patient_session) do
      create :patient_session, :triaged_ready_to_vaccinate
    end

    it { should have_css(".app-consent-banner--purple") }
    it { should have_text("Ready to vaccinate") }
    it "explains who took the decision that the patient should be vaccinated" do
      expect(component.explanation).to eq(
        "A nurse decided that Alya Merton can be vaccinated."
      )
    end
  end

  context "state is unable_to_vaccinate" do
    let(:patient_session) { create :patient_session, :unable_to_vaccinate }

    it { should have_css(".app-consent-banner--orange") }
    it { should have_text("Could not vaccinate") }
    it "explains who took the decision that the patient should be vaccinated" do
      expect(component.explanation).to include(
        "Alya Merton had contraindications"
      )
    end
  end

  context "state is vaccinated" do
    let(:patient_session) { create :patient_session, :vaccinated }

    it { should have_css(".app-consent-banner--green") }
    it { should have_text("Vaccinated") }
    it "explains who gave consent" do
      who_responded = patient_session.consent.who_responded
      expect(component.explanation).to include(
        "Their #{who_responded} gave consent"
      )
    end
  end
end
