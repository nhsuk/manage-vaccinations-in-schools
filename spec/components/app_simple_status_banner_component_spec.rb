# frozen_string_literal: true

describe AppSimpleStatusBannerComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:new_session_patient_triages_path).and_return(
      "/session/patient/triage/new"
    )
  end

  let(:user) { create :user }
  let(:patient_session) { create :patient_session, user: }
  let(:component) { described_class.new(patient_session:) }
  let(:triage_nurse_name) do
    patient_session.latest_triage.performed_by.full_name
  end
  let(:vaccination_nurse_name) do
    patient_session.vaccination_records.last.performed_by.full_name
  end
  let(:patient_name) { patient_session.patient.full_name }

  prepend_before do
    patient_session.patient.update!(given_name: "Alya", family_name: "Merton")
  end

  context "state is added_to_session" do
    let(:patient_session) { create :patient_session, :added_to_session }

    it { should have_css(".app-card--blue") }
  end

  context "state is consent_given_triage_not_needed" do
    let(:patient_session) do
      create :patient_session, :consent_given_triage_not_needed
    end

    it { should have_css(".app-card--aqua-green") }
    it { should have_css(".nhsuk-card__heading", text: "Ready for nurse") }
    it { should have_text("#{patient_name} is ready for the nurse") }
  end

  context "state is consent_given_triage_needed" do
    let(:patient_session) do
      create :patient_session, :consent_given_triage_needed
    end

    it { should have_css(".app-card--blue") }
    it { should have_css(".nhsuk-card__heading", text: "Needs triage") }
    it { should have_text("Responses to health questions need triage") }
  end

  context "state is consent_refused" do
    let(:patient_session) { create :patient_session, :consent_refused }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Consent refused") }
    it { should have_text("refused to give consent") }
  end

  context "state is triaged_kept_in_triage" do
    let(:patient_session) { create :patient_session, :triaged_kept_in_triage }

    it { should have_css(".app-card--blue") }
    it { should have_css(".nhsuk-card__heading", text: "Needs triage") }
    it { should have_text("Responses to health questions need triage") }
  end

  context "state is triaged_ready_to_vaccinate" do
    let(:patient_session) do
      create :patient_session, :triaged_ready_to_vaccinate
    end

    it { should have_css(".app-card--purple") }
    it { should have_css(".nhsuk-card__heading", text: "Safe to vaccinate") }

    it do
      expect(subject).to have_text(
        "#{triage_nurse_name} decided that #{patient_name} is safe to vaccinate"
      )
    end

    it { should have_link("Update triage") }
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) { create :patient_session, :triaged_do_not_vaccinate }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }

    it do
      expect(subject).to have_text(
        "#{triage_nurse_name} decided that #{patient_name} should not be vaccinated"
      )
    end

    it { should have_link("Update triage") }
  end

  context "state is delay_vaccination" do
    let(:patient_session) { create :patient_session, :delay_vaccination }

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }

    it do
      expect(subject).to have_text(
        "#{vaccination_nurse_name} decided that #{patient_name}’s vaccination should be delayed"
      )
    end

    it { should have_link("Update triage") }
  end
end
