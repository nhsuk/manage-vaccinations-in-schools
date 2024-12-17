# frozen_string_literal: true

describe AppPatientVaccinationTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }

  let(:patient) { create(:patient) }

  before { patient.strict_loading!(false) }

  context "without a vaccination record" do
    let(:sessions) { [] }

    it { should have_content("No vaccinations") }
  end

  context "with a not administered vaccination record" do
    before { create(:vaccination_record, :not_administered, patient:) }

    it { should have_content("No vaccinations") }
  end

  context "with a vaccination record" do
    let(:programme) { create(:programme, :hpv) }
    let(:vaccine) { programme.vaccines.active.first }
    let(:location) do
      create(
        :school,
        name: "Test School",
        address_line_1: "Waterloo Road",
        address_town: "London",
        address_postcode: "SE1 8TY"
      )
    end
    let(:session) { create(:session, location:, programme:) }
    let(:vaccination_record) do
      create(
        :vaccination_record,
        patient:,
        programme:,
        session:,
        performed_at: Time.zone.local(2024, 1, 1)
      )
    end

    before { vaccination_record }

    it { should have_link("Gardasil 9 (HPV)") }
    it { should have_content("Test School, Waterloo Road, London, SE1 8TY") }
    it { should have_content("1 January 2024") }
  end
end
