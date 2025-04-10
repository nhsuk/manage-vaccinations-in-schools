# frozen_string_literal: true

describe AppPatientVaccinationTableComponent do
  subject { render_inline(component) }

  let(:component) do
    described_class.new(patient, show_caption:, show_programme:)
  end

  let(:patient) { create(:patient) }
  let(:show_caption) { false }
  let(:show_programme) { false }

  it { should have_content("No vaccinations") }

  context "with a vaccination record" do
    let(:programme) { create(:programme, :hpv) }

    let(:location) do
      create(
        :school,
        name: "Test School",
        address_line_1: "Waterloo Road",
        address_town: "London",
        address_postcode: "SE1 8TY"
      )
    end

    before do
      create(
        :vaccination_record,
        patient:,
        session: create(:session, location:, programmes: [programme]),
        programme:,
        performed_at: Time.zone.local(2024, 1, 1)
      )
    end

    it { should have_link("1 January 2024") }
    it { should have_content("Test School") }
    it { should have_content("Waterloo Road, London, SE1 8TY") }
    it { should have_content("Vaccinated") }
    it { should_not have_content("HPV") }

    context "when showing the programme" do
      let(:show_programme) { true }

      it { should have_content("HPV") }
    end
  end
end
