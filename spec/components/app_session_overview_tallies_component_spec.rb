# frozen_string_literal: true

describe AppSessionOverviewTalliesComponent do
  subject(:rendered) { render_inline(component) }

  let(:hpv_programme) { create(:programme, :hpv) }
  let(:flu_programme) { create(:programme, :flu) }
  let(:session) { create(:session, programmes: [hpv_programme, flu_programme]) }

  let(:component) { described_class.new(session) }

  before { stub_authorization(allowed: true) }

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

  shared_examples "displays correct children due vaccination" do |programme_name, count|
    it "displays correct eligible children for #{programme_name} count" do
      rendered

      programme_section =
        page.find(".nhsuk-heading-m", text: programme_name).ancestor("section")

      expect(programme_section).to have_css(".nhsuk-caption-m", text: count)
    end
  end

  context "with no patient sessions" do
    include_examples "displays correct children due vaccination", "Flu", 0
    include_examples "displays correct count", "Flu", "No response", 0
    include_examples "displays correct count",
                     "Flu",
                     "Consent given for nasal",
                     0
    include_examples "displays correct count",
                     "Flu",
                     "Consent given for injection",
                     0
    include_examples "displays correct count", "Flu", "Did not consent", 0
    include_examples "displays correct count", "Flu", "Vaccinated", 0

    include_examples "displays correct children due vaccination", "HPV", 0
    include_examples "displays correct count", "HPV", "No response", 0
    include_examples "displays correct count", "HPV", "Consent given", 0
    include_examples "displays correct count", "HPV", "Did not consent", 0
    include_examples "displays correct count", "HPV", "Vaccinated", 0
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

      include_examples "displays correct children due vaccination", "Flu", 1
      include_examples "displays correct count", "Flu", "No response", 0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for nasal",
                       0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for injection",
                       0
      include_examples "displays correct count", "Flu", "Did not consent", 0
      include_examples "displays correct count", "Flu", "Vaccinated", 1
    end

    context "there are patients that have consent for nasal and injection" do
      let(:patients) { create_list(:patient, 2, session:, year_group: 9) }

      before do
        create(
          :patient_consent_status,
          :given_injection_only,
          patient: patients.first,
          programme: flu_programme
        )

        create(
          :patient_consent_status,
          :given_nasal_only,
          patient: patients.second,
          programme: flu_programme
        )
      end

      include_examples "displays correct children due vaccination", "Flu", 2
      include_examples "displays correct count", "Flu", "No response", 0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for nasal",
                       1
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for injection",
                       1
      include_examples "displays correct count", "Flu", "Did not consent", 0
      include_examples "displays correct count", "Flu", "Vaccinated", 0
    end

    context "there's a patient that did not consent" do
      before do
        create(
          :patient_consent_status,
          :refused,
          patient:,
          programme: flu_programme
        )
      end

      include_examples "displays correct children due vaccination", "Flu", 1
      include_examples "displays correct count", "Flu", "No response", 0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for nasal",
                       0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for injection",
                       0
      include_examples "displays correct count", "Flu", "Did not consent", 1
      include_examples "displays correct count", "Flu", "Vaccinated", 0
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

      include_examples "displays correct children due vaccination", "HPV", 0
      include_examples "displays correct count", "HPV", "No response", 0
      include_examples "displays correct count", "HPV", "Consent given", 0
      include_examples "displays correct count", "HPV", "Did not consent", 0
      include_examples "displays correct count", "HPV", "Vaccinated", 0
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

      include_examples "displays correct children due vaccination", "Flu", 1
      include_examples "displays correct count", "Flu", "No response", 0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for nasal",
                       0
      include_examples "displays correct count",
                       "Flu",
                       "Consent given for injection",
                       0
      include_examples "displays correct count", "Flu", "Did not consent", 0
      include_examples "displays correct count", "Flu", "Vaccinated", 0
    end

    context "patient was vaccinated for HPV but elsewhere" do
      before do
        create(
          :vaccination_record,
          patient:,
          location: create(:school, name: "Hogwarts"),
          programme: hpv_programme
        )

        StatusUpdater.call(patient:)
      end

      include_examples "displays correct children due vaccination", "HPV", 0
      include_examples "displays correct count", "HPV", "No response", 0
      include_examples "displays correct count", "HPV", "Consent given", 0
      include_examples "displays correct count", "HPV", "Did not consent", 0
      include_examples "displays correct count", "HPV", "Vaccinated", 0
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

      include_examples "displays correct children due vaccination", "HPV", 1
      include_examples "displays correct count", "HPV", "No response", 0
      include_examples "displays correct count", "HPV", "Consent given", 0
      include_examples "displays correct count", "HPV", "Did not consent", 0
      include_examples "displays correct count", "HPV", "Vaccinated", 0
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

        StatusUpdater.call(patient:)
      end

      include_examples "displays correct children due vaccination", "HPV", 1
      include_examples "displays correct count", "HPV", "No response", 0
      include_examples "displays correct count", "HPV", "Consent given", 0
      include_examples "displays correct count", "HPV", "Did not consent", 0
      include_examples "displays correct count", "HPV", "Vaccinated", 0
    end
  end

  context "three patients eligible, one vaccinated, one could not be vaccinated, and one has given consent" do
    let(:patients) { create_list(:patient, 3, session:, year_group: 9) }

    before do
      create(
        :patient_consent_status,
        :given_injection_only,
        patient: patients.first,
        programme: hpv_programme
      )
      create(
        :patient_vaccination_status,
        :vaccinated,
        programme: hpv_programme,
        patient: patients.second
      )
      create(
        :patient_consent_status,
        :refused,
        programme: hpv_programme,
        patient: patients.third
      )
    end

    include_examples "displays correct children due vaccination", "HPV", 3
    include_examples "displays correct count", "HPV", "No response", 0
    include_examples "displays correct count", "HPV", "Consent given", 1
    include_examples "displays correct count", "HPV", "Did not consent", 1
    include_examples "displays correct count", "HPV", "Vaccinated", 1
  end
end
