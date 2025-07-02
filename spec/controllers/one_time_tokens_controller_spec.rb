# frozen_string_literal: true

require "spec_helper"

RSpec.describe OneTimeTokensController do
  let(:user) { create(:user) }
  let(:mock_cis2_info) { { "some_key" => "some value" } }
  let(:valid_token) do
    OneTimeToken.find_or_generate_for!(
      user_id: user.id,
      cis2_info: mock_cis2_info
    )
  end
  let(:invalid_token) { SecureRandom.hex(32) }

  describe "#verify" do
    context "given a valid auth header when auth-by-header is enable" do
      before do
        Flipper.enable(:auth_token_by_header)
        request.headers["Authorization"] = Settings.mavis_reporting_app.secret
      end

      let(:do_the_request) do
        get :verify, params: { token: token.token }, format: :json
      end

      context "and a valid OneTimeToken in the token param" do
        let(:token) { valid_token }

        it "responds with 200" do
          do_the_request
          expect(response.status).to eq(200)
        end

        it "deletes the OneTimeToken" do
          do_the_request
          expect(OneTimeToken.exists?(token.id)).to be(false)
        end

        it "responds with json" do
          do_the_request
          expect(response.headers["Content-type"]).to eq(
            "application/json; charset=utf-8"
          )
        end

        describe "the response json" do
          let(:response_json) { JSON.parse(response.body) }

          it "includes cis2_info" do
            do_the_request
            expect(response_json["cis2_info"]).to eq(mock_cis2_info)
          end

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
                  Settings.mavis_reporting_app.secret,
                  true,
                  { algorithm: "HS512" }
                )
              }.not_to raise_error
            end

            describe "once decoded" do
              let(:decoded_payload) do
                JWT.decode(
                  response_json["jwt"],
                  Settings.mavis_reporting_app.secret,
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

      context "and a OneTimeToken in the token param which can't be found in the users table" do
        let(:do_the_request) do
          get :verify, params: { token: invalid_token }, format: :json
        end
        let(:response_json) { JSON.parse(response.body) }

        it "returns 404" do
          do_the_request
          expect(response.status).to eq(404)
        end

        it "returns an error in the body" do
          do_the_request
          expect(response_json).to eq({ "errors" => "Not found" })
        end
      end
    end
  end
end
