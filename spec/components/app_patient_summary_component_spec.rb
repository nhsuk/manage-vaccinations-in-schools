# frozen_string_literal: true

describe AppPatientSummaryComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient) }

  let(:patient) do
    create(
      :patient,
      given_name: "Hari",
      family_name: "Seldon",
      date_of_birth: Date.new(2000, 1, 1),
      address_postcode: "SW1A 1AA"
    )
  end

  let(:href) { "/patients/#{patient.id}" }

  it { should have_content("SELDON, Hari") }

  it { should have_content("Date of birth") }
  it { should have_content("1 January 2000") }

  it { should have_content("Address") }
  it { should have_content("SW1A 1AA") }

  it { should have_link("View full child record", href:) }
end
