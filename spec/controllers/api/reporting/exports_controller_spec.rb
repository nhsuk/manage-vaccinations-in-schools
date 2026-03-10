# frozen_string_literal: true

describe API::Reporting::ExportsController do
  include ReportingAPIHelper

  let(:team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }
  let(:user) { team.users.first }

  before do
    Flipper.enable(:reporting_api)
    request.headers["Authorization"] = "Bearer #{valid_jwt(team:)}"
    # Stub JWT auth - set up user and session
    cis2_info_hash = {
      "organisation_code" => team.organisation.ods_code,
      "workgroups" => [team.workgroup],
      "team_workgroup" => team.workgroup,
      "role_code" => CIS2Info::NURSE_ROLES.first
    }
    user.cis2_info = CIS2Info.new(request_session: { "cis2_info" => cis2_info_hash })
    allow(controller).to receive(:authenticate_user_by_jwt!) do
      controller.instance_variable_set(:@current_user, user)
      controller.session["user"] = user.as_json
      controller.session["cis2_info"] = cis2_info_hash
    end
  end

  describe "POST #create" do
    let(:params) do
      {
        workgroup: team.workgroup,
        programme_type: "flu",
        academic_year: 2024,
        file_format: "mavis"
      }
    end

    it "creates an export and enqueues job" do
      expect {
        post :create, params: params
      }.to change(VaccinationReportExport, :count).by(1)
        .and have_enqueued_job(GenerateVaccinationReportJob)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["id"]).to be_present
      expect(json["status"]).to eq("pending")
    end

    context "with invalid file_format" do
      before { params[:file_format] = "invalid" }

      it "returns validation errors" do
        post :create, params: params

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "GET #index" do
    let!(:export1) do
      create(:vaccination_report_export, team:, user:, programme_type: "flu", file_format: "mavis")
    end
    let!(:export2) do
      create(:vaccination_report_export, team:, user:, programme_type: "flu", file_format: "systm_one")
    end

    it "returns exports for the current user and team" do
      get :index, params: { workgroup: team.workgroup }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to eq(2)
      expect(json.map { |e| e["id"] }).to contain_exactly(export1.id, export2.id)
      expect(json.first).to include("status", "programme_type", "file_format", "created_at")
    end

    context "when export is ready" do
      before do
        export1.file.attach(
          io: StringIO.new("csv,data"),
          filename: "test.csv",
          content_type: "text/csv"
        )
        export1.ready!
        export1.set_expired_at!
      end

      it "includes download_url for ready exports" do
        get :index, params: { workgroup: team.workgroup }

        json = JSON.parse(response.body)
        ready_export = json.find { |e| e["id"] == export1.id }
        expect(ready_export["download_url"]).to include(export1.id)
        expect(ready_export["download_url"]).to include("/api/reporting/exports/")
      end
    end

    context "when user has exports from another team" do
      let(:other_team) { create(:team, :with_one_nurse, programmes: [Programme.flu]) }

      before do
        user.teams << other_team
        create(:vaccination_report_export, team: other_team, user:, programme_type: "flu")
      end

      it "only returns exports for the requested workgroup" do
        get :index, params: { workgroup: team.workgroup }

        json = JSON.parse(response.body)
        expect(json.size).to eq(2)
        expect(json.map { |e| e["id"] }).to contain_exactly(export1.id, export2.id)
      end
    end
  end

  describe "GET #form_options" do
    before do
      team.programmes << Programme.flu unless team.programme_types.include?("flu")
    end

    it "returns file_formats for the team" do
      get :form_options, params: { workgroup: team.workgroup }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["file_formats"]).to include("mavis", "systm_one")
    end

    context "when team has careplus enabled" do
      let(:team) do
        create(:team, :with_one_nurse, :with_careplus_enabled, programmes: [Programme.flu])
      end

      before { request.headers["Authorization"] = "Bearer #{valid_jwt(team:)}" }

      it "includes careplus" do
        get :form_options, params: { workgroup: team.workgroup }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["file_formats"]).to include("careplus")
      end
    end
  end

  describe "GET #show" do
    let(:export) do
      create(:vaccination_report_export, team:, user:, programme_type: "flu")
    end

    it "returns export status" do
      get :show, params: { id: export.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("pending")
    end

    context "when export is ready" do
      before do
        export.file.attach(
          io: StringIO.new("csv,data"),
          filename: "test.csv",
          content_type: "text/csv"
        )
        export.ready!
        export.set_expired_at!
      end

      it "includes download_url pointing to the API endpoint" do
        get :show, params: { id: export.id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("ready")
        expect(json["download_url"]).to include(export.id)
        expect(json["download_url"]).to include("/api/reporting/exports/")
      end
    end
  end

  describe "GET #download" do
    let(:export) do
      create(:vaccination_report_export, team:, user:, programme_type: "flu")
    end

    before do
      export.file.attach(
        io: StringIO.new("csv,data"),
        filename: "test.csv",
        content_type: "text/csv"
      )
      export.ready!
      export.set_expired_at!
      user.reload
    end

    it "streams the file" do
      get :download, params: { id: export.id }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    context "when export is not ready" do
      before { export.update!(status: "pending") }

      it "returns forbidden" do
        get :download, params: { id: export.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
