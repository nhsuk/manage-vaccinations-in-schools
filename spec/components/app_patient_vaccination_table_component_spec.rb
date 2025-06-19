# frozen_string_literal: true

describe AppPatientVaccinationTableComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient, programme:, show_caption:) }

  let(:patient) { create(:patient) }
  let(:programme) { nil }
  let(:show_caption) { false }

  it { should have_content("No vaccinations") }

  context "with a vaccination record" do
    let(:location) do
      create(
        :school,
        name: "Test School",
        address_line_1: "Waterloo Road",
        address_town: "London",
        address_postcode: "SE1 8TY"
      )
    end

    let(:vaccination_record_programme) { create(:programme, :hpv) }

    before do
      create(
        :vaccination_record,
        patient:,
        session:
          create(
            :session,
            location:,
            programmes: [vaccination_record_programme]
          ),
        programme: vaccination_record_programme,
        performed_at: Time.zone.local(2024, 1, 1)
      )
    end

    it { should have_link("1 January 2024") }
    it { should have_content("Test School") }
    it { should have_content("Waterloo Road, London, SE1 8TY") }
    it { should have_content("Vaccinated") }
    it { should have_content("HPV") }

    context "when showing records from a specific programme" do
      let(:programme) { vaccination_record_programme }

      it { should_not have_content("HPV") }
    end

    context "with a vaccination record from a different programme" do
      let(:programme) { create(:programme, :hpv) }
      let(:vaccination_record_programme) { create(:programme, :flu) }

      it { should_not have_link("1 January 2024") }
      it { should_not have_content("Test School") }
      it { should_not have_content("Waterloo Road, London, SE1 8TY") }
      it { should_not have_content("Vaccinated") }
      it { should_not have_content("HPV") }
    end
  end
end
