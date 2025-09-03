# frozen_string_literal: true

shared_examples "a ReportingAPI controller" do
  let(:team) { create(:team, :with_one_nurse) }
  let(:user) { team.users.first }

  let(:valid_payload) do
    {
      data: {
        user: user.as_json,
        cis2_info: {
          organisation_code: team.organisation.ods_code,
          workgroups: [team.workgroup],
          role_code: CIS2Info::NURSE_ROLE
        }
      }
    }
  end

  let(:valid_jwt) do
    JWT.encode(valid_payload, Settings.reporting_api.client_app.secret, "HS512")
  end

  let(:invalid_payload) { { user: { id: -1 } } }

  context "when the reporting_api feature flag is disabled" do
    before { Flipper.disable(:reporting_api) }

    describe "#index" do
      context "when the request has a JWT param" do
        let(:params) { { jwt: jwt } }

        context "which is valid" do
          let(:jwt) do
            JWT.encode(
              valid_payload,
              Settings.reporting_api.client_app.secret,
              "HS512"
            )
          end

          it "responds with status :forbidden" do
            get :index, params: { jwt: jwt }
            expect(response.status).to eq(403)
          end
        end
      end
    end
  end

  context "when the :reporting_api feature flag is enabled" do
    before { Flipper.enable(:reporting_api) }

    describe "#index" do
      context "when the request has a JWT param" do
        let(:params) { { jwt: jwt } }

        context "which is valid" do
          let(:jwt) do
            JWT.encode(
              valid_payload,
              Settings.reporting_api.client_app.secret,
              "HS512"
            )
          end

          it "responds with status 200" do
            get :index, params: { jwt: jwt }
            expect(response.status).to eq(200)
          end
        end

        context "which is not valid" do
          let(:jwt) do
            JWT.encode(
              invalid_payload,
              Settings.reporting_api.client_app.secret,
              "HS512"
            )
          end

          it "responds with status :forbidden" do
            get :index, params: { jwt: jwt }
            expect(response.status).to eq(403)
          end
        end
      end
    end
  end
end
