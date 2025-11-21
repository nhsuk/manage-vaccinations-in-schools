# frozen_string_literal: true

describe AppSessionOverviewComponent do
  subject(:rendered) { render_inline(component) }

  let(:hpv_programme) { Programme.hpv }
  let(:flu_programme) { Programme.flu }
  let(:session) { create(:session, programmes: [hpv_programme, flu_programme]) }
  let(:latest_location) { session.location }

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
                     "Consent given for gelatine-free injection",
                     0
    include_examples "displays correct count", "Flu", "Consent refused", 0
    include_examples "displays correct count", "Flu", "Vaccinated", 0

    include_examples "displays correct children due vaccination", "HPV", 0
    include_examples "displays correct count", "HPV", "No response", 0
    include_examples "displays correct count", "HPV", "Consent given", 0
    include_examples "displays correct count", "HPV", "Consent refused", 0
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
          programme: flu_programme,
          latest_location:
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
                       "Consent given for gelatine-free injection",
                       0
      include_examples "displays correct count", "Flu", "Consent refused", 0
      include_examples "displays correct count", "Flu", "Vaccinated", 1
    end

    context "there are patients that have consent for nasal and injection" do
      let(:patients) { create_list(:patient, 2, session:, year_group: 9) }

      before do
        create(
          :patient_consent_status,
          :given_without_gelatine,
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
                       "Consent given for gelatine-free injection",
                       1
      include_examples "displays correct count", "Flu", "Consent refused", 0
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
                       "Consent given for gelatine-free injection",
                       0
      include_examples "displays correct count", "Flu", "Consent refused", 1
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
      include_examples "displays correct count", "HPV", "Consent refused", 0
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
                       "Consent given for gelatine-free injection",
                       0
      include_examples "displays correct count", "Flu", "Consent refused", 0
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
      include_examples "displays correct count", "HPV", "Consent refused", 0
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
      include_examples "displays correct count", "HPV", "Consent refused", 0
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
      include_examples "displays correct count", "HPV", "Consent refused", 0
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
        patient: patients.second,
        latest_location:
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
    include_examples "displays correct count", "HPV", "Consent refused", 1
    include_examples "displays correct count", "HPV", "Vaccinated", 1
  end

  describe "rendering vaccination table" do
    subject(:rendered) { travel_to(today) { render_inline(component) } }

    let(:today) { Date.new(2025, 1, 15) }
    let(:programmes) { [Programme.hpv] }
    let(:session) { create(:session, programmes:, dates:) }
    let(:dates) { [Date.new(2025, 1, 15)] }

    context "when session has started" do
      context "when today is the first session date" do
        let(:dates) { [Date.new(2025, 1, 15)] }

        it "renders the vaccinations table" do
          expect(rendered).to have_content("Vaccinations given")
          expect(rendered).to have_content("Session date")
        end

        it "does not render the scheduled dates list" do
          expect(rendered).not_to have_content("Wednesday, 15 January 2025")
        end
      end

      context "when today is after the first session date" do
        let(:dates) { [Date.new(2025, 1, 10), Date.new(2025, 1, 20)] }

        it "renders the vaccinations table" do
          expect(rendered).to have_content("Vaccinations given")
          expect(rendered).to have_content("Session date")
        end
      end

      context "when session has vaccination records on the first date" do
        let(:dates) { [Date.new(2025, 1, 15)] }
        let(:patient) { create(:patient, session:, year_group: 9) }

        before do
          create(
            :vaccination_record,
            patient:,
            session:,
            programme: programmes.first,
            performed_at: Date.new(2025, 1, 15).beginning_of_day
          )
        end

        it "shows vaccinations in the table" do
          expect(rendered).to have_content("Vaccinations given")
          expect(rendered).to have_content("Session date")
        end
      end
    end

    context "when session has not started" do
      let(:dates) { [Date.new(2025, 1, 20)] }

      it "renders the scheduled dates list instead of the table" do
        expect(rendered).to have_content("Monday, 20 January 2025")
        expect(rendered).not_to have_content("Vaccinations given")
        expect(rendered).not_to have_content("Session date")
      end

      it "displays the consent period information" do
        expect(rendered).to have_content("Consent period")
      end
    end
  end
end
