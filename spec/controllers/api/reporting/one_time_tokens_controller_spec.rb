# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Reporting::OneTimeTokensController do
  let(:user) { create(:user) }
  let(:organisation) { create(:organisation) }
  let(:team) { create(:team, organisation:) }
  let(:mock_cis2_info_hash) do
    {
      "organisation_code" => organisation.ods_code,
      "workgroups" => [team.workgroup],
      "role_code" => CIS2Info::NURSE_ROLE,
      "activity_codes" => []
    }
  end
  let(:mock_cis2_info) do
    CIS2Info.new(request_session: { "cis2_info" => mock_cis2_info_hash })
  end
  let(:valid_token) do
    ReportingAPI::OneTimeToken.find_or_generate_for!(
      user:,
      cis2_info: mock_cis2_info_hash
    )
  end
  let(:invalid_token) { SecureRandom.hex(32) }

  before do
    allow(user).to receive_messages(
      cis2_info: mock_cis2_info,
      cis2_enabled?: true
    )
  end

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

          before do
            allow(ReportingAPI::OneTimeToken).to receive(:find_by!).with(
              token: token.token
            ).and_return(token)
            allow(token).to receive(:user).and_return(user)
          end

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

            it "includes a user_nav key" do
              do_the_request
              expect(response_json).to have_key("user_nav")
            end

            describe "the user_nav key" do
              before { do_the_request }

              it "is a hash with items array" do
                expect(response_json["user_nav"]).to be_a(Hash)
                expect(response_json["user_nav"]).to have_key("items")
                expect(response_json["user_nav"]["items"]).to be_an(Array)
              end

              it "includes the user display name in the first item" do
                expected_display_name = user.full_name
                expected_display_name +=
                  " (#{user.role_description})" if user.role_description.present?
                expect(response_json["user_nav"]["items"][0]["text"]).to eq(
                  expected_display_name
                )
              end

              it "includes a logout link in the second item" do
                expect(response_json["user_nav"]["items"][1]["href"]).to eq(
                  "/logout"
                )
                expect(response_json["user_nav"]["items"][1]["text"]).to eq(
                  "Log out"
                )
              end
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
                    Settings.reporting_api.client_app.secret,
                    true,
                    {
                      algorithm:
                        ReportingAPI::OneTimeToken::JWT_SIGNING_ALGORITHM
                    }
                  )
                }.not_to raise_error
              end

              describe "once decoded" do
                let(:decoded_payload) do
                  JWT.decode(
                    response_json["jwt"],
                    Settings.reporting_api.client_app.secret,
                    true,
                    {
                      algorithm:
                        ReportingAPI::OneTimeToken::JWT_SIGNING_ALGORITHM
                    }
                  )
                end
                let(:jwt_data) { decoded_payload.first["data"] }

                it "includes the user attributes" do
                  do_the_request
                  expect(jwt_data["user"]).to eq(user.as_json)
                end

                it "includes the users cis2_info" do
                  do_the_request
                  expect(jwt_data["cis2_info"]).to eq(mock_cis2_info_hash)
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

  describe "#authorize reconstructs cis2_info from token" do
    let(:organisation) { create(:organisation) }
    let(:team) { create(:team, organisation:) }
    let(:user) { create(:user) }
    let(:cis2_info_hash) do
      {
        "organisation_code" => organisation.ods_code,
        "workgroups" => [team.workgroup],
        "role_code" => CIS2Info::NURSE_ROLE,
        "activity_codes" => []
      }
    end
    let(:token) do
      ReportingAPI::OneTimeToken.find_or_generate_for!(
        user:,
        cis2_info: cis2_info_hash
      )
    end

    before { Flipper.enable(:reporting_api) }

    it "returns 200" do
      post :authorize,
           params: {
             code: token.token,
             grant_type: "authorization_code",
             client_id: Settings.reporting_api.client_app.client_id
           },
           format: :json
      expect(response.status).to eq(200)
    end
  end
end
