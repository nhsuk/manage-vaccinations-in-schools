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
      create(:vaccination_record, patient: patient1, programme:, session:, outcome: "administered")

      # Patient 2: Vaccinated
      patient2 = create(:patient, session:)
      create(:vaccination_record, patient: patient2, programme:, session:, outcome: "administered")

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
  end
end
