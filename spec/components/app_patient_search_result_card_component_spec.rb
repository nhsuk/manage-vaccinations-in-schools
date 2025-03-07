# frozen_string_literal: true

describe AppPatientSearchResultCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient, link_to:) }

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

  it { should have_link("SELDON, Hari", href: "/patient") }
  it { should have_text("1 January 2000") }

  context "when showing the postcode" do
    let(:component) do
      described_class.new(patient, link_to:, show_postcode: true)
    end

    it { should have_text("SW11 1AA") }
  end

  context "when showing the programme outcome" do
    let(:programme) { create(:programme, :flu) }

    let(:component) { described_class.new(patient, link_to:, programme:) }

    it { should have_text("Programme outcome\nFluNo outcome yet") }
  end

  context "when showing the school" do
    let(:component) do
      described_class.new(patient, link_to:, show_school: true)
    end

    it { should have_text("Streeling University") }
  end
end
