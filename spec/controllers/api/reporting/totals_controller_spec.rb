# frozen_string_literal: true

describe API::Reporting::TotalsController do
  before do
    Flipper.enable(:reporting_api)
    request.headers["Authorization"] = "Bearer #{valid_jwt}"
  end

  include ReportingAPIHelper

  let(:parsed_response) { JSON.parse(response.body) }

  it_behaves_like "a ReportingAPI controller"

  describe "#index" do
    it "returns all expected keys" do
      get :index

      expect(response).to have_http_status(:ok)
      expect(parsed_response).to have_key("cohort")
      expect(parsed_response).to have_key("vaccinated")
      expect(parsed_response).to have_key("not_vaccinated")
      expect(parsed_response).to have_key("vaccinated_by_sais")
      expect(parsed_response).to have_key("vaccinated_elsewhere_declared")
      expect(parsed_response).to have_key("vaccinated_elsewhere_recorded")
      expect(parsed_response).to have_key("vaccinated_previously")
      expect(parsed_response).to have_key("vaccinations_given")
      expect(parsed_response).to have_key("monthly_vaccinations_given")
    end

    it "calculates statistics correctly" do
      team = Team.last # The most recently created team from valid_jwt
      programme = create(:programme, teams: [team])
      session = create(:session, team:, programmes: [programme])

      # Patient 1: Vaccinated
      patient1 = create(:patient, session:)
      create(
        :vaccination_record,
        patient: patient1,
        programme:,
        session:,
        outcome: "administered"
      )

      # Patient 2: Vaccinated
      patient2 = create(:patient, session:)
      create(
        :vaccination_record,
        patient: patient2,
        programme:,
        session:,
        outcome: "administered"
      )

      # Patient 3: Not vaccinated (should be counted as not_vaccinated)
      create(:patient, session:)

      ReportingAPI::PatientProgrammeStatus.refresh!

      get :index

      expect(response).to have_http_status(:ok)

      cohort = parsed_response["cohort"]
      vaccinated = parsed_response["vaccinated"]
      not_vaccinated = parsed_response["not_vaccinated"]

      expect(cohort).to eq(3) # 3 distinct patients
      expect(vaccinated).to eq(2) # patient1 and patient2
      expect(not_vaccinated).to eq(1) # patient3
      expect(vaccinated + not_vaccinated).to eq(cohort)

      expect(parsed_response["vaccinated_by_sais"]).to eq(2) # patient1 and patient2
      expect(parsed_response["vaccinated_elsewhere_declared"]).to eq(0) # no declared external vaccinations
      expect(parsed_response["vaccinated_elsewhere_recorded"]).to eq(0) # no recorded external vaccinations
      expect(parsed_response["vaccinated_previously"]).to eq(0) # no previous year vaccinations
      expect(parsed_response["vaccinations_given"]).to eq(2) # 2 administered records
      expect(parsed_response["monthly_vaccinations_given"]).to be_an(Array)
    end

    it "filters by multiple year groups" do
      team = Team.last
      programme = create(:programme, teams: [team])
      session = create(:session, team:, programmes: [programme])

      create(:patient, session:, year_group: 8)
      create(:patient, session:, year_group: 8)
      create(:patient, session:, year_group: 9)
      create(:patient, session:, year_group: 10)
      create(:patient, session:, year_group: 10)

      ReportingAPI::PatientProgrammeStatus.refresh!

      get :index, params: { year_group: [8, 9] }

      expect(response).to have_http_status(:ok)
      expect(parsed_response["cohort"]).to eq(3)
    end
  end

  describe "#index.csv" do
    it "returns grouped CSV data by year group" do
      team = Team.last
      programme = create(:programme, :hpv, teams: [team])
      session = create(:session, team:, programmes: [programme])

      create(:patient, session:, year_group: 8)
      create(:patient, session:, year_group: 9)

      ReportingAPI::PatientProgrammeStatus.refresh!

      request.headers["Accept"] = "text/csv"
      get :index, params: { group: "year_group" }, format: :csv

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")

      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to include("Year Group", "Cohort", "Vaccinated")
      expect(csv.length).to eq(2)
    end
  end

  describe "Dashboard acceptance criteria" do
    let(:team) { Team.last }
    let(:hpv_programme) { create(:programme, :hpv, teams: [team]) }
    let(:hpv_session) { create(:session, team:, programmes: [hpv_programme]) }
    let(:flu_programme) { create(:programme, :flu, teams: [team]) }
    let(:flu_session) { create(:session, team:, programmes: [flu_programme]) }
    let(:menacwy_programme) { create(:programme, :menacwy, teams: [team]) }
    let(:menacwy_session) do
      create(:session, team:, programmes: [menacwy_programme])
    end
    let(:td_ipv_programme) { create(:programme, :td_ipv, teams: [team]) }
    let(:td_ipv_session) do
      create(:session, team:, programmes: [td_ipv_programme])
    end

    let(:cohort) { parsed_response["cohort"] }
    let(:vaccinated) { parsed_response["vaccinated"] }
    let(:not_vaccinated) { parsed_response["not_vaccinated"] }
    let(:vaccinated_by_sais) { parsed_response["vaccinated_by_sais"] }
    let(:vaccinated_elsewhere_declared) do
      parsed_response["vaccinated_elsewhere_declared"]
    end
    let(:vaccinated_elsewhere_recorded) do
      parsed_response["vaccinated_elsewhere_recorded"]
    end
    let(:vaccinations_given) { parsed_response["vaccinations_given"] }
    let(:monthly_vaccinations_given) do
      parsed_response["monthly_vaccinations_given"]
    end

    def refresh_and_get_totals(programme_type: "hpv")
      ReportingAPI::PatientProgrammeStatus.refresh!(concurrently: false)
      get :index, params: { programme: programme_type }
      expect(response).to have_http_status(:ok)
    end

    it "child vaccinated by SAIS" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: hpv_session,
        outcome: "administered",
        performed_at: Time.current
      )

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_by_sais).to eq(1)
      expect(vaccinations_given).to eq(1)

      monthly =
        monthly_vaccinations_given.find do
          it["year"] == Time.current.year &&
            it["month"] == Date::MONTHNAMES[Time.current.month]
        end
      expect(monthly).to be_present
      expect(monthly["count"]).to eq(1)
    end

    it "historic record uploaded" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: nil,
        source: "historical_upload",
        outcome: "administered",
        performed_at: 3.months.ago
      )

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(vaccinations_given).to eq(1)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "child already had vaccination" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        :already_had,
        patient:,
        programme: hpv_programme,
        session: hpv_session,
        performed_at: Time.current
      )

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_elsewhere_declared).to eq(1)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "vaccination imported from FHIR API" do
      patient = create(:patient, session: flu_session)

      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: nil,
        source: "nhs_immunisations_api",
        outcome: "administered",
        performed_at: 3.months.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(vaccinations_given).to eq(1)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "already had and FHIR API import" do
      patient = create(:patient, session: flu_session)

      create(
        :vaccination_record,
        :already_had,
        patient:,
        programme: flu_programme,
        session: flu_session,
        performed_at: Time.current
      )
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: nil,
        source: "nhs_immunisations_api",
        outcome: "administered",
        performed_at: 3.months.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_elsewhere_declared).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "ineligible vaccination imported from FHIR API" do
      patient = create(:patient, session: flu_session)

      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: nil,
        source: "nhs_immunisations_api",
        outcome: "administered",
        performed_at: 1.year.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(vaccinated_elsewhere_recorded).to eq(0)
      expect(vaccinations_given).to eq(1)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "child refuses vaccination" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: hpv_session,
        outcome: "refused",
        performed_at: Time.current
      )

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(vaccinated_by_sais).to eq(0)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "parent refuses consent" do
      patient = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: nil,
        source: "consent_refusal",
        outcome: "refused",
        performed_at: Time.current
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(vaccinated_by_sais).to eq(0)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "child moves in with eligible vaccination record" do
      other_team = create(:team, programmes: [flu_programme])
      other_session =
        create(:session, team: other_team, programmes: [flu_programme])

      patient = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: other_session,
        outcome: "administered",
        performed_at: 2.months.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_by_sais).to eq(1)
      expect(vaccinations_given).to eq(1)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "child moves out with eligible vaccination record" do
      other_team = create(:team, programmes: [flu_programme])
      other_session =
        create(:session, team: other_team, programmes: [flu_programme])

      patient = create(:patient, session: other_session)
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: flu_session,
        outcome: "administered",
        performed_at: 2.months.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(0)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_by_sais).to eq(0)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "counts HPV cohort correctly across years 8 to 11" do
      create(:patient, session: hpv_session, year_group: 8)
      create(:patient, session: hpv_session, year_group: 8)
      create(:patient, session: hpv_session, year_group: 9)
      create(:patient, session: hpv_session, year_group: 10)
      create(:patient, session: hpv_session, year_group: 11)

      create(:patient, session: hpv_session, year_group: 7)
      create(:patient, session: hpv_session, year_group: 12)

      refresh_and_get_totals

      expect(cohort).to eq(5)
    end

    it "counts flu cohort correctly across reception to year 11" do
      create(:patient, session: flu_session, year_group: 0)
      create(:patient, session: flu_session, year_group: 1)
      create(:patient, session: flu_session, year_group: 5)
      create(:patient, session: flu_session, year_group: 11)

      create(:patient, session: flu_session, year_group: 12)
      create(:patient, session: flu_session, year_group: 13)

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(4)
    end

    it "counts MenACWY cohort correctly across years 9 to 11" do
      create(:patient, session: menacwy_session, year_group: 9)
      create(:patient, session: menacwy_session, year_group: 10)
      create(:patient, session: menacwy_session, year_group: 11)

      create(:patient, session: menacwy_session, year_group: 8)
      create(:patient, session: menacwy_session, year_group: 12)

      refresh_and_get_totals(programme_type: "menacwy")

      expect(cohort).to eq(3)
    end

    it "counts Td/IPV cohort correctly across years 9 to 11" do
      create(:patient, session: td_ipv_session, year_group: 9)
      create(:patient, session: td_ipv_session, year_group: 10)
      create(:patient, session: td_ipv_session, year_group: 11)

      create(:patient, session: td_ipv_session, year_group: 8)
      create(:patient, session: td_ipv_session, year_group: 12)

      refresh_and_get_totals(programme_type: "td_ipv")

      expect(cohort).to eq(3)
    end

    it "counts year 12 students when session location has year 12 enabled" do
      send_location =
        create(
          :school,
          gias_year_groups: (0..12).to_a,
          team:,
          programmes: [flu_programme],
          academic_year: AcademicYear.current
        )
      send_session =
        create(
          :session,
          location: send_location,
          team:,
          programmes: [flu_programme]
        )

      create(
        :location_programme_year_group,
        location: send_location,
        programme: flu_programme,
        year_group: 12,
        academic_year: AcademicYear.current
      )

      create(:patient, session: send_session, year_group: 11)
      create(:patient, session: send_session, year_group: 12)

      create(:patient, session: flu_session, year_group: 12)

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(2)
    end

    it "does not count year 12 students without SEND school enablement" do
      create(:patient, session: hpv_session, year_group: 12)
      create(:patient, session: flu_session, year_group: 12)
      create(:patient, session: menacwy_session, year_group: 12)
      create(:patient, session: td_ipv_session, year_group: 12)

      refresh_and_get_totals(programme_type: "hpv")
      expect(cohort).to eq(0)

      refresh_and_get_totals(programme_type: "flu")
      expect(cohort).to eq(0)

      refresh_and_get_totals(programme_type: "menacwy")
      expect(cohort).to eq(0)

      refresh_and_get_totals(programme_type: "td_ipv")
      expect(cohort).to eq(0)
    end

    it "does not count year 7 students for HPV, MenACWY and Td/IPV" do
      create(:patient, session: hpv_session, year_group: 7)
      create(:patient, session: menacwy_session, year_group: 7)
      create(:patient, session: td_ipv_session, year_group: 7)

      refresh_and_get_totals(programme_type: "hpv")
      expect(cohort).to eq(0)

      refresh_and_get_totals(programme_type: "menacwy")
      expect(cohort).to eq(0)

      refresh_and_get_totals(programme_type: "td_ipv")
      expect(cohort).to eq(0)
    end

    it "does not count year 8 students for MenACWY and Td/IPV" do
      create(:patient, session: menacwy_session, year_group: 8)
      create(:patient, session: td_ipv_session, year_group: 8)

      refresh_and_get_totals(programme_type: "menacwy")
      expect(cohort).to eq(0)

      refresh_and_get_totals(programme_type: "td_ipv")
      expect(cohort).to eq(0)
    end
  end
end
