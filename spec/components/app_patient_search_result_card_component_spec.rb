# frozen_string_literal: true

describe AppPatientSearchResultCardComponent do
  subject { render_inline(component) }

  let(:patient) do
    create(
      :patient,
      address_postcode: "SW11 1AA",
      date_of_birth: Date.new(2020, 1, 1),
      family_name: "Seldon",
      given_name: "Hari",
      nhs_number: "9000000009",
      school: build(:school, name: "Streeling University")
    )
  end

  let(:link_to) { "/patient" }
  let(:programmes) { [] }
  let(:academic_year) { nil }
  let(:show_consent_status) { false }
  let(:show_nhs_number) { false }
  let(:show_postcode) { false }
  let(:show_school) { false }
  let(:show_triage_status) { false }

  let(:component) do
    described_class.new(
      patient,
      link_to:,
      programmes:,
      academic_year:,
      show_consent_status:,
      show_nhs_number:,
      show_postcode:,
      show_school:,
      show_triage_status:
    )
  end

  it { should have_link("SELDON, Hari", href: "/patient") }
  it { should have_text("1 January 2020") }
  it { should_not have_text("900 000 0009") }
  it { should_not have_text("SW11 1AA") }
  it { should_not have_text("Streeling University") }

  context "when showing the NHS number" do
    let(:show_nhs_number) { true }

    it { should have_text("900 000 0009") }
  end

  context "when showing the postcode" do
    let(:show_postcode) { true }

    it { should have_text("SW11 1AA") }
  end

  context "when showing the school" do
    let(:show_school) { true }

    it { should have_text("Streeling University") }
  end

  context "when given programmes" do
    let(:programme) { Programme.flu }
    let(:programmes) { [programme] }
    let(:academic_year) { AcademicYear.current }

    it { should have_text("Programme statusFluNot eligible") }
    it { should_not have_text("Triage status") }
    it { should_not have_text("Consent status") }

    context "when showing the consent status" do
      let(:show_consent_status) { true }

      it { should have_text("Consent statusFluNo response") }
    end

    context "when showing the triage status" do
      let(:show_triage_status) { true }

      it { should have_text("Triage statusFluNo triage needed") }
    end

    context "with a session status of unwell" do
      before do
        create(
          :patient_vaccination_status,
          :eligible,
          patient:,
          programme:,
          latest_date: Date.new(2025, 1, 1),
          latest_session_status: "unwell"
        )
      end

      it { should have_text("Programme statusFluEligibleUnwell") }
    end
  end
end
