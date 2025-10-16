# frozen_string_literal: true

describe AppPatientSearchResultCardComponent do
  subject { render_inline(component) }

  let(:patient) do
    create(
      :patient,
      given_name: "Hari",
      family_name: "Seldon",
      date_of_birth: Date.new(2000, 1, 1),
      address_postcode: "SW11 1AA",
      school: build(:school, name: "Streeling University")
    )
  end

  let(:link_to) { "/patient" }
  let(:programme) { nil }
  let(:academic_year) { nil }
  let(:show_triage_status) { false }
  let(:show_postcode) { false }
  let(:show_school) { false }

  let(:component) do
    described_class.new(
      patient,
      link_to:,
      programme:,
      academic_year:,
      show_triage_status:,
      show_postcode:,
      show_school:
    )
  end

  it { should have_link("SELDON, Hari", href: "/patient") }
  it { should have_text("1 January 2000") }
  it { should_not have_text("SW11 1AA") }
  it { should_not have_text("Streeling University") }

  context "when showing the postcode" do
    let(:show_postcode) { true }

    it { should have_text("SW11 1AA") }
  end

  context "when showing the school" do
    let(:show_school) { true }

    it { should have_text("Streeling University") }
  end

  context "when given a programme" do
    let(:programme) { create(:programme, :flu) }
    let(:academic_year) { Date.current.academic_year }

    it { should have_text("Programme outcomeFluNo outcome") }

    context "when given a consent status" do
      let(:consent_status) { "given" }

      it { should have_text("Consent statusFluNo response") }
    end

    it { should_not have_text("Triage status") }

    context "when showing the triage status" do
      let(:show_triage_status) { true }

      it { should have_text("Triage statusFluNo triage needed") }
    end

    context "when the patient has a triage status" do
      before { create(:patient_triage_status, :required, patient:, programme:) }

      it { should have_text("Triage statusFluNeeds triage") }
    end

    context "with a session status of unwell" do
      before do
        create(
          :patient_vaccination_status,
          :none_yet,
          patient:,
          programme:,
          latest_session_status: "unwell"
        )
      end

      it { should have_text("Programme outcomeFluNo outcomeUnwell") }
    end
  end
end
