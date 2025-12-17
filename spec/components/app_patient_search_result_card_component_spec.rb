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
  let(:current_team) { create(:team) }
  let(:programmes) { [] }
  let(:academic_year) { nil }
  let(:show_nhs_number) { false }
  let(:show_postcode) { false }
  let(:show_school) { false }

  let(:component) do
    described_class.new(
      patient,
      link_to:,
      current_team:,
      programmes:,
      academic_year:,
      show_nhs_number:,
      show_postcode:,
      show_school:
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

  context "with the flu programme" do
    let(:programme) { Programme.flu }
    let(:programmes) { [programme] }

    it { should have_text("Programme statusFluNot eligible") }

    context "with a session status of unwell" do
      before do
        create(
          :patient_programme_status,
          :cannot_vaccinate_unwell,
          patient:,
          programme:
        )
      end

      it { should have_text("FluUnable to vaccinateChild unwell") }
    end
  end

  context "with the MMR(V) programme" do
    let(:programme) { Programme.mmr }
    let(:programmes) { [programme] }

    context "with a patient not eligible for MMRV" do
      let(:patient) { create(:patient, date_of_birth: Date.new(2019, 1, 1)) }

      it { should have_text("Programme statusMMR") }
      it { should_not have_text("MMRV") }
    end

    context "with a patient eligible for MMRV" do
      let(:patient) { create(:patient, date_of_birth: Date.new(2020, 1, 1)) }

      it { should have_text("Programme statusMMRV") }
    end
  end
end
