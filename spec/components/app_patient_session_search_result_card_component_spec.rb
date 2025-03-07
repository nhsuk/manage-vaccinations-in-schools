# frozen_string_literal: true

describe AppPatientSessionSearchResultCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient_session, context:) }

  let(:patient) do
    create(
      :patient,
      given_name: "Hari",
      family_name: "Seldon",
      address_postcode: "SW11 1AA",
      year_group: 8,
      school: build(:school, name: "Streeling University")
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient_session) { create(:patient_session, patient:, session:) }
  let(:context) { :consent }

  let(:href) do
    "/sessions/#{session.slug}/patients/#{patient.id}/hpv?return_to=consent"
  end

  it { should have_link("SELDON, Hari", href:) }
  it { should have_text("Year 8") }
  it { should have_text("Status") }

  context "when context is register" do
    let(:context) { :register }

    it { should have_text("Action required\nGet consent for HPV") }
  end

  context "when context is record" do
    let(:context) { :record }

    it { should have_text("Action required\nGet consent for HPV") }
  end
end
