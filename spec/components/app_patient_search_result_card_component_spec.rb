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

  it { should have_link("Hari Seldon", href: "/patient") }
  it { should have_text("1 January 2000") }
  it { should have_text("SW11 1AA") }
  it { should have_text("Streeling University") }
end
