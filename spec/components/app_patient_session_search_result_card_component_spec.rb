# frozen_string_literal: true

describe AppPatientSessionSearchResultCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient_session, link_to:, context:) }

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

  let(:patient_session) { create(:patient_session, patient:) }

  let(:link_to) { "/patient-session" }

  let(:context) { :consent }

  it { should have_link("SELDON, Hari", href: "/patient-session") }
  it { should have_text("1 January 2000") }
  it { should have_text("Status") }
end
