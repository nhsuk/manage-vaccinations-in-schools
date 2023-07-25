require "rails_helper"

RSpec.describe AppStatusBannerComponent, type: :component do
  before { render_inline(component) }

  let(:patient_session) { create :patient_session }
  let(:component) { described_class.new(patient_session:) }

  subject { page }

  context "state is added_to_session" do
    let(:patient_session) { create :patient_session, :added_to_session }

    it { should have_css(".app-consent-banner--yellow") }
  end

  context "state is consent_given_triage_not_needed" do
    let(:patient_session) { create :patient_session, :consent_given_triage_not_needed }

    it { should have_css(".app-consent-banner--purple") }
    it { should have_text("Ready to vaccinate") }
    # banner_explanation: Jane Doe decided that %{full_name} can be vaccinated.
  end

  context "state is consent_given_triage_needed" do
    let(:patient_session) { create :patient_session, :consent_given_triage_needed }

    it { should have_css(".app-consent-banner--blue") }
    it { should have_text("Triage needed") }
  end

  context "state is consent_refused" do
    let(:patient_session) { create :patient_session, :consent_refused }

    it { should have_css(".app-consent-banner--orange") }
    it { should have_text("Their mum has refused to give consent.") }
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) { create :patient_session, :triaged_do_not_vaccinate }

    it { should have_css(".app-consent-banner--red") }
    it { should have_text("Do not vaccinate") }
    # banner_explanation: Jane Doe decided that %{full_name} should not be vaccinated.
  end

  context "state is triaged_kept_in_triage" do
    let(:patient_session) { create :patient_session, :triaged_kept_in_triage }

    it { should have_css(".app-consent-banner--aqua-green") }
    it { should have_text("Triage started") }
  end

  context "state is triaged_ready_to_vaccinate" do
    let(:patient_session) { create :patient_session, :triaged_ready_to_vaccinate }

    it { should have_css(".app-consent-banner--purple") }
    it { should have_text("Ready to vaccinate") }
    # banner_explanation: Jane Doe decided that %{full_name} can be vaccinated.
  end

  context "state is unable_to_vaccinate" do
    let(:patient_session) { create :patient_session, :unable_to_vaccinate }

    it { should have_css(".app-consent-banner--orange") }
    it { should have_text("Could not vaccinate") }
    # banner_explanation:
    #   refused: "%{full_name} refused it"
    #   now_well: "%{full_name} was not well enough"
    #   contraindications: "%{full_name} had contraindications"
    #   already_had: "%{full_name} has already had the vaccine"
    #   absent_from_school: "%{full_name} was absent from school"
    #   absent_from_session: "%{full_name} was absent from the session"
    #   gave_consent: "Their %{who_responded} gave consent"
  end

  context "state is vaccinated" do
    let(:patient_session) { create :patient_session, :vaccinated }

    it { should have_css(".app-consent-banner--green") }
    it { should have_text("Vaccinated") }
    # banner_explanation: Their %{who_responded} gave consent
  end
end
