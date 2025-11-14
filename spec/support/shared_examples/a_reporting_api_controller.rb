# frozen_string_literal: true

shared_examples "a ReportingAPI controller" do
  include ReportingAPIHelper

  # Extract the user from the JWT payload so we're testing with the same user
  # that was authenticated via JWT
  let(:jwt_payload) { valid_jwt_payload }
  let(:user) { User.find(jwt_payload[:data][:user]["id"]) }
  let(:team) { user.teams.first }

  context "when the reporting_api feature flag is disabled" do
    before { Flipper.disable(:reporting_api) }

    describe "#index" do
      context "when the request has a JWT param" do
        let(:params) { { jwt: jwt } }

        context "which is valid" do
          let(:jwt) { valid_jwt(jwt_payload) }

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
          let(:jwt) { valid_jwt(jwt_payload) }

          it "responds with status 200" do
            get :index, params: { jwt: jwt }
            expect(response.status).to eq(200)
          end

          it "establishes a Warden session with activity tracking" do
            get :index, params: { jwt: jwt }

            expect(
              request.session.dig("warden.user.user.session", "last_request_at")
            ).to be_a(Integer)
          end
        end

        context "which is not valid" do
          let(:jwt) { jwt_with_invalid_payload }

          it "responds with status :forbidden" do
            get :index, params: { jwt: jwt }
            expect(response.status).to eq(403)
          end
        end
      end
    end
  end
end
