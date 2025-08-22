# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Reporting::OneTimeTokensController do
  let(:user) { create(:user) }
  let(:mock_cis2_info) { { "some_key" => "some value" } }
  let(:valid_token) do
    ReportingAPI::OneTimeToken.find_or_generate_for!(
      user:,
      cis2_info: mock_cis2_info
    )
  end
  let(:invalid_token) { SecureRandom.hex(32) }

  describe "#authorize" do
    context "given a valid client_id when reporting_api is enabled" do
      before { Flipper.enable(:reporting_api) }

      let(:client_id) { Settings.reporting_api.client_app.client_id }
      let(:grant_type) { "some_grant_type" }

      let(:do_the_request) do
        post :authorize,
             params: {
               code: token.token,
               grant_type: grant_type,
               client_id: client_id
             },
             format: :json
      end

      context "and a valid OneTimeToken in the code param" do
        let(:token) { valid_token }

        context "and a grant_type which is not authorization_code" do
          let(:grant_type) { "not_an_authorization_code" }

          it "responds with HTTP 400" do
            do_the_request
            expect(response.status).to eq(400)
          end

          describe "the response json" do
            let(:response_json) { JSON.parse(response.body) }

            it "has an error key set to unsupported_grant_type" do
              do_the_request
              expect(response_json["error"]).to eq("unsupported_grant_type")
            end
          end
        end
      end

      context "and a grant_type of authorization_code" do
        # this param name and value is required by the OAUTH 2.0 spec
        # see https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
        let(:grant_type) { "authorization_code" }

        context "and a valid OneTimeToken in the code param" do
          let(:token) { valid_token }

          it "responds with 200" do
            do_the_request
            expect(response.status).to eq(200)
          end

          it "deletes the OneTimeToken" do
            do_the_request
            expect(ReportingAPI::OneTimeToken.exists?(token.id)).to be(false)
          end

          it "responds with json" do
            do_the_request
            expect(response.headers["Content-type"]).to eq(
              "application/json; charset=utf-8"
            )
          end

          describe "the response json" do
            let(:response_json) { JSON.parse(response.body) }

            it "includes a JWT" do
              do_the_request
              expect(response_json["jwt"]).not_to be_empty
            end

            describe "the JWT payload" do
              let(:payload) { response_json["jwt"] }

              it "is encoded with the Mavis reporting app secret" do
                do_the_request
                expect {
                  JWT.decode(
                    response_json["jwt"],
                    Settings.reporting_api.client_app.secret,
                    true,
                    { algorithm: "HS512" }
                  )
                }.not_to raise_error
              end

              describe "once decoded" do
                let(:decoded_payload) do
                  JWT.decode(
                    response_json["jwt"],
                    Settings.reporting_api.client_app.secret,
                    true,
                    { algorithm: "HS512" }
                  )
                end
                let(:jwt_data) { decoded_payload.first["data"] }

                it "includes the user attributes" do
                  do_the_request
                  expect(jwt_data["user"]).to eq(user.as_json)
                end

                it "includes the users cis2_info" do
                  do_the_request
                  expect(jwt_data["cis2_info"]).to eq(mock_cis2_info)
                end
              end
            end
          end
        end

        context "and a OneTimeToken in the code param which can't be found in the users table" do
          let(:do_the_request) do
            post :authorize,
                 params: {
                   code: invalid_token,
                   grant_type: grant_type,
                   client_id: client_id
                 },
                 format: :json
          end
          let(:response_json) { JSON.parse(response.body) }

          it "returns 403" do
            do_the_request
            expect(response.status).to eq(403)
          end

          it "returns an error in the body" do
            do_the_request
            expect(response_json).to eq({ "errors" => "invalid_grant" })
          end
        end
      end
    end
  end
end
