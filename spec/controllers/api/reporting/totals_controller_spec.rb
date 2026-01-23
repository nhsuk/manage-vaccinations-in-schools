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

    it "does not include flu-specific keys for non-flu programmes" do
      get :index

      expect(response).to have_http_status(:ok)
      expect(parsed_response).not_to have_key("vaccinated_nasal")
      expect(parsed_response).not_to have_key("vaccinated_injection")
      expect(parsed_response).not_to have_key("consent_given_nasal_only")
      expect(parsed_response).not_to have_key("consent_given_injection_only")
      expect(parsed_response).not_to have_key("consent_given_both_methods")
    end

    it "includes flu-specific keys when filtering by flu programme" do
      get :index, params: { programme: "flu" }

      expect(response).to have_http_status(:ok)
      expect(parsed_response).to have_key("vaccinated_nasal")
      expect(parsed_response).to have_key("vaccinated_injection")
      expect(parsed_response).to have_key("consent_given_nasal_only")
      expect(parsed_response).to have_key("consent_given_injection_only")
      expect(parsed_response).to have_key("consent_given_both_methods")
    end

    it "calculates statistics correctly" do
      team = Team.last # The most recently created team from valid_jwt
      programme = Programme.hpv
      team.programmes << programme
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

      refresh_reporting_views!

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
      programme = Programme.flu
      team.programmes << programme
      session = create(:session, team:, programmes: [programme])

      create(:patient, session:, year_group: 8)
      create(:patient, session:, year_group: 8)
      create(:patient, session:, year_group: 9)
      create(:patient, session:, year_group: 10)
      create(:patient, session:, year_group: 10)

      refresh_reporting_views!

      get :index, params: { year_group: [8, 9] }

      expect(response).to have_http_status(:ok)
      expect(parsed_response["cohort"]).to eq(3)
    end

    it "filters by workgroup" do
      programme = Programme.flu

      team = Team.last
      team.programmes << programme

      other_team = create(:team, organisation: team.organisation)
      other_team.programmes << programme

      session = create(:session, team:, programmes: [programme])
      other_session =
        create(:session, team: other_team, programmes: [programme])

      create(:patient, session:)
      create(:patient, session:)
      create(:patient, session: other_session)

      refresh_reporting_views!

      get :index, params: { workgroup: team.workgroup }

      expect(response).to have_http_status(:ok)
      expect(parsed_response["cohort"]).to eq(2)
    end

    it "filters by team_workgroup from session when no workgroup param" do
      programme = Programme.flu
      team = Team.last
      team.programmes << programme
      other_team = create(:team, organisation: team.organisation)
      other_team.programmes << programme

      user = team.users.first
      user.teams << other_team

      create(
        :patient,
        session: create(:session, team:, programmes: [programme])
      )
      create(
        :patient,
        session: create(:session, team:, programmes: [programme])
      )
      create(
        :patient,
        session: create(:session, team: other_team, programmes: [programme])
      )

      refresh_reporting_views!

      jwt =
        JWT.encode(
          {
            data: {
              user: user.as_json,
              cis2_info: {
                organisation_code: team.organisation.ods_code,
                workgroups: [team.workgroup, other_team.workgroup],
                team_workgroup: team.workgroup,
                role_code: CIS2Info::NURSE_ROLE
              }
            }
          },
          Settings.reporting_api.client_app.secret,
          "HS512"
        )
      request.headers["Authorization"] = "Bearer #{jwt}"

      get :index

      expect(response).to have_http_status(:ok)
      expect(parsed_response["cohort"]).to eq(2)
    end

    it "returns grouped JSON data by school" do
      team = Team.last
      programme = Programme.hpv
      team.programmes << programme
      session = create(:session, team:, programmes: [programme])

      school_one = create(:school, name: "School One", urn: "111111")
      school_two = create(:school, name: "School Two", urn: "222222")

      create(:patient, session:, school: school_one)
      patient2 = create(:patient, session:, school: school_two)
      create(
        :vaccination_record,
        patient: patient2,
        programme:,
        session:,
        outcome: "administered",
        performed_at: Time.current
      )

      create(:patient, session:, school: nil, home_educated: true)
      create(:patient, session:, school: nil, home_educated: false)

      refresh_reporting_views!

      get :index, params: { group: "school", programme: "hpv" }

      expect(response).to have_http_status(:ok)
      expect(parsed_response).to be_an(Array)
      expect(parsed_response.length).to eq(4)

      school_one_data = parsed_response.find { it["school_urn"] == "111111" }
      school_two_data = parsed_response.find { it["school_urn"] == "222222" }
      home_educated_data = parsed_response.find { it["school_urn"] == "999999" }
      unknown_data = parsed_response.find { it["school_urn"] == "888888" }

      expect(school_one_data["school_name"]).to eq("School One")
      expect(school_one_data["cohort"]).to eq(1)
      expect(school_one_data["vaccinated"]).to eq(0)
      expect(school_one_data["not_vaccinated"]).to eq(1)

      expect(school_two_data["school_name"]).to eq("School Two")
      expect(school_two_data["cohort"]).to eq(1)
      expect(school_two_data["vaccinated"]).to eq(1)
      expect(school_two_data["not_vaccinated"]).to eq(0)

      expect(home_educated_data["school_name"]).to eq("Home-schooled")
      expect(home_educated_data["cohort"]).to eq(1)
      expect(home_educated_data["vaccinated"]).to eq(0)
      expect(home_educated_data["not_vaccinated"]).to eq(1)

      expect(unknown_data["school_name"]).to eq("Unknown school")
      expect(unknown_data["cohort"]).to eq(1)
      expect(unknown_data["vaccinated"]).to eq(0)
      expect(unknown_data["not_vaccinated"]).to eq(1)
    end
  end

  describe "#index.csv" do
    it "returns grouped CSV data by year group" do
      team = Team.last
      programme = Programme.hpv
      team.programmes << programme
      session = create(:session, team:, programmes: [programme])

      create(:patient, session:, year_group: 8)
      create(:patient, session:, year_group: 9)

      refresh_reporting_views!

      request.headers["Accept"] = "text/csv"
      get :index, params: { group: "year_group" }, format: :csv

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")

      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to include("Year Group", "Cohort", "Vaccinated")
      expect(csv.length).to eq(2)
    end

    it "returns grouped CSV data by school" do
      team = Team.last
      programme = Programme.hpv
      team.programmes << programme
      session = create(:session, team:, programmes: [programme])

      school_one = create(:school, name: "School One", urn: "111111")
      school_two = create(:school, name: "School Two", urn: "222222")

      create(:patient, session:, school: school_one)
      create(:patient, session:, school: school_two)

      refresh_reporting_views!

      request.headers["Accept"] = "text/csv"
      get :index, params: { group: "school" }, format: :csv

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")

      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to include(
        "School URN",
        "School Name",
        "Cohort",
        "Vaccinated"
      )
      expect(csv.length).to eq(2)
    end
  end

  describe "Dashboard acceptance criteria" do
    let(:team) { Team.last }
    let(:cohort) { parsed_response["cohort"] }
    let(:vaccinated) { parsed_response["vaccinated"] }
    let(:not_vaccinated) { parsed_response["not_vaccinated"] }
    let(:vaccinated_by_sais) { parsed_response["vaccinated_by_sais"] }
    let(:vaccinated_previously) { parsed_response["vaccinated_previously"] }
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
    let(:hpv_programme) { Programme.hpv }
    let(:hpv_session) { create(:session, team:, programmes: [hpv_programme]) }
    let(:flu_programme) { Programme.flu }
    let(:flu_session) { create(:session, team:, programmes: [flu_programme]) }
    let(:menacwy_programme) { Programme.menacwy }
    let(:menacwy_session) do
      create(:session, team:, programmes: [menacwy_programme])
    end
    let(:td_ipv_programme) { Programme.td_ipv }
    let(:td_ipv_session) do
      create(:session, team:, programmes: [td_ipv_programme])
    end

    before do
      team.programmes << hpv_programme
      team.programmes << flu_programme
      team.programmes << menacwy_programme
      team.programmes << td_ipv_programme
    end

    def refresh_and_get_totals(programme_type: "hpv")
      refresh_reporting_views!
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

    it "counts vaccination in correct month when performed during BST" do
      patient = create(:patient, session: hpv_session)
      create(
          :vaccination_record,
          patient:,
          programme: hpv_programme,
          session: hpv_session,
          outcome: "administered",
          performed_at: Time.zone.local(2024, 9, 1, 0, 30) # 00:30 BST = 23:30 UTC (Aug 31)
        )

      refresh_and_get_totals

      monthly =
        monthly_vaccinations_given.find do
          it["year"] == 2024 && it["month"] == "September"
        end
      expect(monthly).to be_present,
      "Expected vaccination to be counted in September, not August"
      expect(monthly["count"]).to eq(1)
    end

    it "child archived after being vaccinated by SAIS" do
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
      initial_response = JSON.parse(response.body)

      create(:archive_reason, patient:, team:, type: "moved_out_of_area")

      refresh_and_get_totals
      final_response = JSON.parse(response.body)

      expect(final_response["cohort"]).to eq(initial_response["cohort"] - 1)
      expect(final_response["vaccinated"]).to eq(
        initial_response["vaccinated"] - 1
      )
      expect(final_response["not_vaccinated"]).to eq(
        initial_response["not_vaccinated"]
      )
      expect(final_response["vaccinations_given"]).to eq(
        initial_response["vaccinations_given"]
      )
      expect(final_response["monthly_vaccinations_given"]).to eq(
        initial_response["monthly_vaccinations_given"]
      )
    end

    it "child deceased after being vaccinated by SAIS" do
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
      initial_response = JSON.parse(response.body)

      patient.update!(date_of_death: Date.current)

      refresh_and_get_totals
      final_response = JSON.parse(response.body)

      expect(final_response["cohort"]).to eq(initial_response["cohort"] - 1)
      expect(final_response["vaccinated"]).to eq(
        initial_response["vaccinated"] - 1
      )
      expect(final_response["not_vaccinated"]).to eq(
        initial_response["not_vaccinated"]
      )
      expect(final_response["vaccinated_by_sais"]).to eq(
        initial_response["vaccinated_by_sais"] - 1
      )
      expect(final_response["vaccinations_given"]).to eq(
        initial_response["vaccinations_given"]
      )
      expect(final_response["monthly_vaccinations_given"]).to eq(
        initial_response["monthly_vaccinations_given"]
      )
    end

    it "historic hpv record uploaded" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: nil,
        source: "historical_upload",
        outcome: "administered",
        performed_at: 1.year.ago
      )

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_previously).to eq(1)
      expect(vaccinated_elsewhere_recorded).to eq(0)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "current hpv record uploaded" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: nil,
        source: "historical_upload",
        outcome: "administered",
        performed_at: Time.current
      )

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_previously).to eq(0)
      expect(vaccinated_by_sais).to eq(0)
      expect(vaccinated_elsewhere_declared).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "historic flu record uploaded" do
      patient = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: nil,
        source: "historical_upload",
        outcome: "administered",
        performed_at: 1.year.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)

      # flu is seasonal so vaccinations from a previous year don't count
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(vaccinated_previously).to eq(0)

      expect(vaccinated_elsewhere_recorded).to eq(0)
      expect(vaccinations_given).to eq(0)
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
      expect(vaccinations_given).to eq(0)
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
        nhs_immunisations_api_identifier_system: "ABC",
        nhs_immunisations_api_identifier_value: "123",
        outcome: "administered",
        performed_at: Time.current
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_previously).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(vaccinations_given).to eq(0)
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
        nhs_immunisations_api_identifier_system: "ABC",
        nhs_immunisations_api_identifier_value: "123",
        outcome: "administered",
        performed_at: Time.current
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_elsewhere_declared).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(vaccinations_given).to eq(0)
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
        nhs_immunisations_api_identifier_system: "ABC",
        nhs_immunisations_api_identifier_value: "123",
        outcome: "administered",
        performed_at: 1.year.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      # flu is seasonal so vaccinations from a previous year don't count
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(1)
      expect(parsed_response["vaccinated_previously"]).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(0)
      expect(vaccinations_given).to eq(0)
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

    it "parent refuses consent claiming already vaccinated (consent only)" do
      patient = create(:patient, session: flu_session)
      create(
        :consent,
        :refused,
        patient:,
        programme: flu_programme,
        team:,
        reason_for_refusal: "already_vaccinated"
      )

      StatusUpdater.call(patient:)
      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_elsewhere_declared).to eq(1)
      expect(vaccinated_elsewhere_recorded).to eq(0)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "parent refuses consent claiming already vaccinated and FHIR API import" do
      patient = create(:patient, session: flu_session)

      create(
        :consent,
        :refused,
        patient:,
        programme: flu_programme,
        team:,
        reason_for_refusal: "already_vaccinated"
      )
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: nil,
        source: "nhs_immunisations_api",
        nhs_immunisations_api_identifier_system: "ABC",
        nhs_immunisations_api_identifier_value: "123",
        outcome: "administered",
        performed_at: Time.current
      )

      StatusUpdater.call(patient:)
      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(1)
      expect(vaccinated).to eq(1)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_elsewhere_declared).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(1)
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
      expect(vaccinated_by_sais).to eq(0)
      expect(vaccinated_elsewhere_recorded).to eq(1)
      expect(vaccinations_given).to eq(0)
      expect(monthly_vaccinations_given).to be_empty
    end

    it "child moves out with eligible vaccination record" do
      other_org = create(:organisation)
      other_team =
        create(:team, programmes: [flu_programme], organisation: other_org)
      other_school = create(:school, team: other_team)

      patient = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: flu_session,
        outcome: "administered",
        performed_at: Time.current # Current academic year for monthly breakdown
      )

      SchoolMove.create!(
        patient:,
        school: other_school,
        academic_year: AcademicYear.current,
        source: :cohort_import
      ).confirm!(user: create(:user))

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(0)
      expect(vaccinated).to eq(0)
      expect(not_vaccinated).to eq(0)
      expect(vaccinated_by_sais).to eq(0)

      # Child moved out, but vaccination was given by this team
      # so it should be counted as given
      expect(vaccinations_given).to eq(1)
      monthly =
        monthly_vaccinations_given.find do
          it["year"] == Time.current.year &&
            it["month"] == Date::MONTHNAMES[Time.current.month]
        end
      expect(monthly).to be_present
      expect(monthly["count"]).to eq(1)
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

    it "only counts Td/IPV dose 5 as vaccinated previously" do
      patient = create(:patient, session: td_ipv_session, year_group: 9)
      create(
        :vaccination_record,
        patient:,
        programme: td_ipv_programme,
        session: nil,
        source: "nhs_immunisations_api",
        nhs_immunisations_api_identifier_system: "test",
        nhs_immunisations_api_identifier_value: "123",
        dose_sequence: 4,
        performed_at: 1.year.ago
      )

      refresh_and_get_totals(programme_type: "td_ipv")

      expect(vaccinated_previously).to eq(0)
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

    it "counts children with consent given" do
      patient = create(:patient, session: hpv_session)
      create(:consent, :given, patient:, programme: hpv_programme, team:)

      StatusUpdater.call(patient:)
      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(parsed_response["consent_given"]).to eq(1)
      expect(parsed_response["consent_no_response"]).to eq(0)
    end

    it "counts children with no consent response" do
      create(:patient, session: hpv_session)

      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(parsed_response["consent_given"]).to eq(0)
      expect(parsed_response["consent_no_response"]).to eq(1)
    end

    it "counts children with conflicting consent" do
      patient = create(:patient, session: hpv_session)
      parent1 = create(:parent)
      parent2 = create(:parent)
      create(:parent_relationship, patient:, parent: parent1)
      create(:parent_relationship, patient:, parent: parent2)

      create(
        :consent,
        :given,
        patient:,
        programme: hpv_programme,
        team:,
        parent: parent1
      )
      create(
        :consent,
        :refused,
        patient:,
        programme: hpv_programme,
        team:,
        parent: parent2
      )

      StatusUpdater.call(patient:)
      refresh_and_get_totals

      expect(cohort).to eq(1)
      expect(parsed_response["consent_conflicts"]).to eq(1)
    end

    it "distinguishes parent refused vs child refused" do
      patient1 = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient: patient1,
        programme: hpv_programme,
        session: nil,
        source: "consent_refusal",
        outcome: "refused",
        # TODO: Fix the way academic year is calculated in the reporting
        #  views. Currently it uses the year from the date, but that's not
        #  correct. For example, 1st January 2026 is in the 2025/26 academic
        #  year, which is stored as the value of 2025.
        # performed_at: Time.current,
        performed_at:
          hpv_session.academic_year.to_academic_year_date_range.begin
      )

      patient2 = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient: patient2,
        programme: hpv_programme,
        session: hpv_session,
        outcome: "refused",
        performed_at: Time.current
      )

      refresh_and_get_totals

      expect(cohort).to eq(2)
      expect(parsed_response["parent_refused_consent"]).to eq(1)
      expect(parsed_response["child_refused_vaccination"]).to eq(1)
    end

    it "returns consent refusal reasons breakdown" do
      patient1 = create(:patient, session: hpv_session)
      create(
        :consent,
        :refused,
        patient: patient1,
        programme: hpv_programme,
        team:,
        reason_for_refusal: "personal_choice"
      )

      patient2 = create(:patient, session: hpv_session)
      create(
        :consent,
        :refused,
        patient: patient2,
        programme: hpv_programme,
        team:,
        reason_for_refusal: "personal_choice"
      )

      patient3 = create(:patient, session: hpv_session)
      create(
        :consent,
        :refused,
        patient: patient3,
        programme: hpv_programme,
        team:,
        reason_for_refusal: "already_vaccinated"
      )

      refresh_and_get_totals

      refusal_reasons = parsed_response["refusal_reasons"]
      expect(refusal_reasons).to be_a(Hash)
      expect(refusal_reasons["personal_choice"]).to eq(2)
      expect(refusal_reasons["already_vaccinated"]).to eq(1)
    end

    it "returns consent routes breakdown" do
      patient1 = create(:patient, session: hpv_session)
      create(
        :consent,
        :given,
        patient: patient1,
        programme: hpv_programme,
        team:,
        route: "website"
      )

      patient2 = create(:patient, session: hpv_session)
      create(
        :consent,
        :given,
        patient: patient2,
        programme: hpv_programme,
        team:,
        route: "website"
      )

      patient3 = create(:patient, session: hpv_session)
      create(
        :consent,
        :given,
        patient: patient3,
        programme: hpv_programme,
        team:,
        route: "phone",
        recorded_by: create(:user)
      )

      refresh_and_get_totals

      consent_routes = parsed_response["consent_routes"]
      expect(consent_routes).to be_a(Hash)
      expect(consent_routes["website"]).to eq(2)
      expect(consent_routes["phone"]).to eq(1)
    end

    it "counts vaccinations by delivery method for flu" do
      patient1 = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient: patient1,
        programme: flu_programme,
        session: flu_session,
        outcome: "administered",
        delivery_method: "nasal_spray",
        performed_at: Time.current
      )

      patient2 = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient: patient2,
        programme: flu_programme,
        session: flu_session,
        outcome: "administered",
        delivery_method: "intramuscular",
        performed_at: Time.current
      )

      patient3 = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient: patient3,
        programme: flu_programme,
        session: flu_session,
        outcome: "administered",
        delivery_method: "subcutaneous",
        performed_at: Time.current
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(3)
      expect(vaccinated).to eq(3)
      expect(parsed_response["vaccinated_nasal"]).to eq(1)
      expect(parsed_response["vaccinated_injection"]).to eq(2)
    end

    it "counts consent by vaccine method for flu" do
      patient1 = create(:patient, session: flu_session)
      create(
        :consent,
        :given,
        patient: patient1,
        programme: flu_programme,
        team:,
        vaccine_methods: ["nasal"]
      )

      patient2 = create(:patient, session: flu_session)
      create(
        :consent,
        :given,
        patient: patient2,
        programme: flu_programme,
        team:,
        vaccine_methods: ["injection"]
      )

      patient3 = create(:patient, session: flu_session)
      create(
        :consent,
        :given,
        patient: patient3,
        programme: flu_programme,
        team:,
        vaccine_methods: %w[nasal injection]
      )

      StatusUpdater.call(patient: patient1)
      StatusUpdater.call(patient: patient2)
      StatusUpdater.call(patient: patient3)

      refresh_and_get_totals(programme_type: "flu")

      expect(cohort).to eq(3)
      expect(parsed_response["consent_given_nasal_only"]).to eq(1)
      expect(parsed_response["consent_given_injection_only"]).to eq(1)
      expect(parsed_response["consent_given_both_methods"]).to eq(1)
    end

    it "counts patient in current year category only when vaccinated both years" do
      patient = create(:patient, session: hpv_session)
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: nil,
        source: "historical_upload",
        outcome: "administered",
        performed_at: 1.year.ago
      )
      create(
        :vaccination_record,
        patient:,
        programme: hpv_programme,
        session: hpv_session,
        outcome: "administered",
        performed_at: Time.current
      )

      refresh_and_get_totals

      expect(vaccinated).to eq(1)
      expect(vaccinated_by_sais).to eq(1)
      expect(vaccinated_previously).to eq(0)
    end

    it "does not count previous flu vaccination from team session" do
      previous_flu_session =
        create(
          :session,
          team:,
          programmes: [flu_programme],
          date: 1.year.ago.to_date
        )
      patient = create(:patient, session: flu_session)
      create(
        :vaccination_record,
        patient:,
        programme: flu_programme,
        session: previous_flu_session,
        outcome: "administered",
        performed_at: 1.year.ago
      )

      refresh_and_get_totals(programme_type: "flu")

      expect(vaccinated).to eq(0)
      expect(vaccinated_previously).to eq(0)
    end
  end
end
