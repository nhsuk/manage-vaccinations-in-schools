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
  let(:triage_status) { "" }
  let(:show_postcode) { false }
  let(:show_school) { false }

  let(:component) do
    described_class.new(
      patient,
      link_to:,
      programme:,
      academic_year:,
      triage_status:,
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

    it { should have_text("Programme outcome\nFluNo outcome") }
    it { should_not have_text("Triage status") }

    context "when given a consent status" do
      let(:consent_status) { "given" }

      it { should have_text("Consent status\nFluNo response") }
    end

    context "when given a triage status" do
      let(:triage_status) { "safe_to_vaccinate" }

      it { should have_text("Triage status\nFluNo triage needed") }
    end

    context "when triage status is 'Any' and a patient's triage status is required" do
      let(:triage_status) { "" }

      before { create(:patient_triage_status, :required, patient:, programme:) }

      it { should have_text("Triage status\nFluNeeds triage") }
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

      it { should have_text("Programme outcome\nFluNo outcomeUnwell") }
    end
  end
end
