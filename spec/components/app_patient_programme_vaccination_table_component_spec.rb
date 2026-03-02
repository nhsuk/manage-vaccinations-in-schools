# frozen_string_literal: true

describe AppPatientProgrammeVaccinationTableComponent do
  subject { render_inline(component) }

  let(:component) do
    described_class.new(patient, academic_year:, programme:, show_caption:)
  end

  let(:patient) { create(:patient) }
  let(:academic_year) { 2023 }
  let(:programme) { Programme.hpv }
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

    let(:vaccination_record_programme) { Programme.hpv }
    let(:performed_at) { Time.zone.local(2024, 1, 1) }

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
        performed_at:
      )
    end

    it { should have_css(".nhsuk-table__header", text: "Vaccination date") }
    it { should have_css(".nhsuk-table__header", text: "Age") }
    it { should have_css(".nhsuk-table__header", text: "Programme") }
    it { should have_css(".nhsuk-table__header", text: "Source") }

    it { should have_link("1 January 2024") }
    it { should have_content("#{patient.age_years(now: performed_at)} years") }
    it { should have_content("HPV") }
    it { should have_content("Recorded in Mavis") }

    context "with a vaccination record from a different programme" do
      let(:programme) { Programme.hpv }
      let(:vaccination_record_programme) { Programme.flu }

      it { should_not have_link("1 January 2024") }
      it do
        should_not have_content("#{patient.age_years(now: performed_at)} years")
      end
      it { should_not have_content("HPV") }
      it { should_not have_content("Recorded in Mavis") }
    end

    context "with a Flu vaccination record from a previous year" do
      let(:vaccination_record_programme) { Programme.flu }
      let(:programme) { vaccination_record_programme }
      let(:performed_at) { Time.zone.local(2022, 1, 1) }

      it { should_not have_link("1 January 2022") }
      it do
        should_not have_content("#{patient.age_years(now: performed_at)} years")
      end
      it { should_not have_content("Flu") }
      it { should_not have_content("Recorded in Mavis") }
    end
  end
end
