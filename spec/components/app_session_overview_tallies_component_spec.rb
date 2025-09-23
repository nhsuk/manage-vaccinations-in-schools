# frozen_string_literal: true

describe AppSessionOverviewTalliesComponent do
  subject(:rendered) { render_inline(component) }

  let(:hpv_programme) { create(:programme, :hpv) }
  let(:flu_programme) { create(:programme, :flu) }
  let(:session) { create(:session, programmes: [hpv_programme, flu_programme]) }

  let(:component) { described_class.new(session) }

  shared_examples "displays correct count" do |programme_name, tally_name, count|
    it "displays correct #{tally_name.downcase} count" do
      rendered

      programme_section =
        page.find(".nhsuk-heading-m", text: programme_name).ancestor("section")
      tally =
        programme_section.find(
          ".nhsuk-card__heading",
          text: tally_name
        ).ancestor(".nhsuk-card")

      expect(tally).to have_css(".nhsuk-card__description", text: count)
    end
  end

  shared_examples "displays correct consent count" do |consent_tally_name, count|
    it "displays correct #{consent_tally_name.downcase} count" do
      rendered

      tally =
        page.find(".nhsuk-card__heading", text: consent_tally_name).ancestor(
          ".nhsuk-card"
        )

      expect(tally).to have_css(".nhsuk-card__description", text: count)
    end
  end

  context "with no patient sessions" do
    include_examples "displays correct count", "Flu", "Eligible cohort", 0
    include_examples "displays correct count", "Flu", "Vaccinated", 0
    include_examples "displays correct count", "Flu", "Could not vaccinate", 0
    include_examples "displays correct count", "Flu", "No outcome", 0

    include_examples "displays correct count", "HPV", "Eligible cohort", 0
    include_examples "displays correct count", "HPV", "Vaccinated", 0
    include_examples "displays correct count", "HPV", "Could not vaccinate", 0
    include_examples "displays correct count", "HPV", "No outcome", 0
  end

  context "when a patient exists in year 9" do
    let(:patient) { create(:patient, session:, year_group: 9) }

    context "they have been vaccinated during the session" do
      before do
        create(
          :patient_vaccination_status,
          :vaccinated,
          patient:,
          programme: flu_programme
        )
      end

      include_examples "displays correct count", "Flu", "Eligible cohort", 1
      include_examples "displays correct count", "Flu", "Vaccinated", 1
      include_examples "displays correct count", "Flu", "Could not vaccinate", 0
      include_examples "displays correct count", "Flu", "No outcome", 0
    end

    context "they could not be vaccinated" do
      before do
        create(
          :patient_vaccination_status,
          :could_not_vaccinate,
          patient:,
          programme: flu_programme
        )
      end

      include_examples "displays correct count", "Flu", "Eligible cohort", 1
      include_examples "displays correct count", "Flu", "Vaccinated", 0
      include_examples "displays correct count", "Flu", "Could not vaccinate", 1
      include_examples "displays correct count", "Flu", "No outcome", 0
    end

    context "there is no outcome yet for the patient" do
      before do
        create(
          :patient_vaccination_status,
          :none_yet,
          patient:,
          programme: flu_programme
        )
      end

      include_examples "displays correct count", "Flu", "Eligible cohort", 1
      include_examples "displays correct count", "Flu", "Vaccinated", 0
      include_examples "displays correct count", "Flu", "Could not vaccinate", 0
      include_examples "displays correct count", "Flu", "No outcome", 1
    end

    context "patient was vaccinated in previous years" do
      before do
        create(
          :patient_vaccination_status,
          :vaccinated,
          patient:,
          programme: hpv_programme,
          academic_year: AcademicYear.current - 1
        )
      end

      include_examples "displays correct count", "HPV", "Eligible cohort", 0
      include_examples "displays correct count", "HPV", "Vaccinated", 0
      include_examples "displays correct count", "HPV", "Could not vaccinate", 0
      include_examples "displays correct count", "HPV", "No outcome", 0
    end

    context "patient had seasonal vaccination in previous years" do
      before do
        create(
          :patient_vaccination_status,
          :vaccinated,
          patient:,
          programme: flu_programme,
          academic_year: AcademicYear.current - 1
        )
      end

      include_examples "displays correct count", "Flu", "Eligible cohort", 1
      include_examples "displays correct count", "Flu", "Vaccinated", 0
      include_examples "displays correct count", "Flu", "Could not vaccinate", 0
      include_examples "displays correct count", "Flu", "No outcome", 0
    end

    context "patient was vaccinated for HPV but elsewhere" do
      before do
        create(
          :vaccination_record,
          patient:,
          location: create(:school, name: "Hogwarts"),
          programme: hpv_programme
        )
      end

      include_examples "displays correct count", "HPV", "Eligible cohort", 0
      include_examples "displays correct count", "HPV", "Vaccinated", 0
      include_examples "displays correct count", "HPV", "Could not vaccinate", 0
      include_examples "displays correct count", "HPV", "No outcome", 0
    end

    context "patient refused HPV vaccine elsewhere" do
      before do
        create(
          :vaccination_record,
          patient:,
          location: create(:school, name: "Hogwarts"),
          programme: hpv_programme,
          outcome: "refused"
        )
      end

      include_examples "displays correct count", "HPV", "Eligible cohort", 1
      include_examples "displays correct count", "HPV", "Vaccinated", 0
      include_examples "displays correct count", "HPV", "Could not vaccinate", 0
      include_examples "displays correct count", "HPV", "No outcome", 0
    end

    context "with multiple patients and one was vaccinated for HPV elsewhere" do
      let(:other_school) { create(:school) }

      before do
        create(
          :vaccination_record,
          :refused,
          patient: create(:patient, session:, year_group: 9),
          location: other_school,
          programme: hpv_programme
        )

        create(
          :vaccination_record,
          patient:,
          location: other_school,
          programme: hpv_programme
        )
      end

      include_examples "displays correct count", "HPV", "Eligible cohort", 1
      include_examples "displays correct count", "HPV", "Vaccinated", 0
      include_examples "displays correct count", "HPV", "Could not vaccinate", 0
      include_examples "displays correct count", "HPV", "No outcome", 0
    end
  end

  context "three patients eligible, one vaccinated, one could not be vaccinated, and one had no outcome" do
    let(:patients) { create_list(:patient, 3, session:, year_group: 9) }

    before do
      create(
        :patient_vaccination_status,
        :none_yet,
        programme: hpv_programme,
        patient: patients.first
      )
      create(
        :patient_vaccination_status,
        :vaccinated,
        programme: hpv_programme,
        patient: patients.second
      )
      create(
        :patient_vaccination_status,
        :could_not_vaccinate,
        programme: hpv_programme,
        patient: patients.third
      )
    end

    include_examples "displays correct count", "HPV", "Eligible cohort", 3
    include_examples "displays correct count", "HPV", "Vaccinated", 1
    include_examples "displays correct count", "HPV", "Could not vaccinate", 1
    include_examples "displays correct count", "HPV", "No outcome", 1
  end
end
