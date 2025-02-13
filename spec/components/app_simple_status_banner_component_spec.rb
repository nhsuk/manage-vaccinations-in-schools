# frozen_string_literal: true

describe AppSimpleStatusBannerComponent do
  subject(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:new_session_patient_triages_path).and_return(
      "/session/patient/triage/new"
    )
    stub_authorization(allowed: true)

    patient_session.strict_loading!(false)
    patient_session.patient.strict_loading!(false)
  end

  let(:user) { create(:user) }
  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programme:, user:) }

  let(:component) { described_class.new(patient_session:) }

  let(:triage_nurse_name) do
    patient_session.triages(programme:).last.performed_by.full_name
  end
  let(:vaccination_nurse_name) do
    patient_session.vaccination_records(programme:).last.performed_by.full_name
  end
  let(:patient_name) { patient_session.patient.full_name }

  prepend_before do
    patient_session.patient.update!(given_name: "Alya", family_name: "Merton")
  end

  context "state is added_to_session" do
    let(:patient_session) do
      create(:patient_session, :added_to_session, programme:)
    end

    it { should have_css(".app-card--blue") }
  end

  context "state is consent_given_triage_not_needed" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_not_needed, programme:)
    end

    it { should have_css(".app-card--aqua-green") }
    it { should have_css(".nhsuk-card__heading", text: "Ready for nurse") }
    it { should have_text("#{patient_name} is ready for the nurse") }
  end

  context "state is consent_given_triage_needed" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_needed, programme:)
    end

    it { should have_css(".app-card--blue") }
    it { should have_css(".nhsuk-card__heading", text: "Needs triage") }
    it { should have_text("Responses to health questions need triage") }
  end

  context "state is consent_refused" do
    let(:patient_session) do
      create(:patient_session, :consent_refused, programme:)
    end

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Consent refused") }
    it { should have_text("refused to give consent") }
  end

  context "state is triaged_kept_in_triage" do
    let(:patient_session) do
      create(:patient_session, :triaged_kept_in_triage, programme:)
    end

    it { should have_css(".app-card--blue") }
    it { should have_css(".nhsuk-card__heading", text: "Needs triage") }
    it { should have_text("Responses to health questions need triage") }
  end

  context "state is triaged_ready_to_vaccinate" do
    let(:patient_session) do
      create(:patient_session, :triaged_ready_to_vaccinate, programme:)
    end

    it { should have_css(".app-card--purple") }
    it { should have_css(".nhsuk-card__heading", text: "Ready for nurse") }

    it do
      expect(rendered).to have_text(
        "#{triage_nurse_name} decided that #{patient_name} is ready for the nurse"
      )
    end

    it { should have_link("Update triage") }
  end

  context "state is triaged_do_not_vaccinate" do
    let(:patient_session) do
      create(:patient_session, :triaged_do_not_vaccinate, programme:)
    end

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }

    it do
      expect(rendered).to have_text(
        "#{triage_nurse_name} decided that #{patient_name} should not be vaccinated"
      )
    end

    it { should have_link("Update triage") }
  end

  context "state is delay_vaccination" do
    let(:patient_session) do
      create(:patient_session, :delay_vaccination, programme:)
    end

    it { should have_css(".app-card--red") }
    it { should have_css(".nhsuk-card__heading", text: "Could not vaccinate") }

    it do
      expect(rendered).to have_text(
        "#{vaccination_nurse_name} decided that #{patient_name}’s vaccination should be delayed"
      )
    end

    it { should have_link("Update triage") }
  end
end
