# frozen_string_literal: true

require_relative Rails.root.join("lib/omniauth/strategies/nhsuk_cis2")

describe ::OmniAuth::Strategies::NhsukCis2 do # rubocop:disable RSpec/SpecFilePathFormat
  let(:server_private_key) do
    OpenSSL::PKey::RSA.new(
      File.read(Rails.root.join("spec/fixtures/cis2_server_rsa_private.pem"))
    )
  end
  let(:server_public_key) { server_private_key.server_public_key }

  let(:issuer) do
    "https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc"
  end

  ## Authorization endpoint #########################################
  let(:authorization_endpoint) { "#{issuer}/authorize" }

  ## Access token endpoint ##########################################
  let(:access_token) { "access_token" }
  let(:access_token_response) do
    {
      access_token:,
      scope:
        "openid nationalrbacaccess profile selectedrole associatedorgs email",
      token_type: "Bearer",
      expires_in: 3599,
      nonce: "a215d543d4018caf1e05707e142d297f",
      id_token: id_token_rs256_jwt
    }
  end

  ## Userinfo endpoint #############################################
  let(:userinfo_endpoint) { "#{issuer}/userinfo" }
  let(:userinfo) do
    {
      nhsid_useruid: "555057896106",
      name: "Flo Nurse",
      nhsid_nrbac_roles: [
        {
          person_orgid: "555057897107",
          person_roleid: "555057898108",
          org_code: "X26",
          role_name:
            "\"Admin and Clerical\":\"Admin and Clerical\":\"Privacy Officer\"",
          role_code: "S8002:G8003:R0001",
          activities: [
            "Receive Self Claimed LR Alerts",
            "Receive Legal Override and Emergency View Alerts",
            "Receive Sealing Alerts"
          ],
          activity_codes: %w[B0016 B0015 B0018]
        },
        {
          person_orgid: "555057995106",
          person_roleid: "555057996107",
          org_code: "Y51",
          role_name:
            "\"Clinical\":\"Clinical Provision\":\"Nurse Access Role\"",
          role_code: "S8000:G8000:R8001",
          activities: [
            "Personal Medication Administration",
            "Perform Detailed Health Record",
            "Amend Patient Demographics",
            "Perform Patient Administration",
            "Verify Health Records"
          ],
          activity_codes: %w[B0428 B0380 B0825 B0560 B8028]
        }
      ],
      given_name: "Nurse",
      family_name: "Flo",
      uid: "555057896106",
      nhsid_user_orgs: [
        { "org_name" => "NHS ENGLAND - X26", "org_code" => "X26" },
        {
          "org_name" =>
            "THE NORTH MIDLANDS AND EAST PROGRAMME FOR IT (NMEPFIT)",
          "org_code" => "Y51"
        }
      ],
      email: "nurse.flo@example.nhs.uk",
      sub: "555057896106"
    }
  end

  ## Token endpoint #################################################
  let(:token_endpoint) { "#{issuer}/access_token" }
  let(:id_token) do
    {
      at_hash: "at_hash.test",
      sub: "555057896106",
      auditTrackingId: "auditTrackingId.test",
      amr: ["pwd"],
      iss:
        "https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc",
      tokenName: "id_token",
      sid: "sid.test",
      id_assurance_level: "3",
      acr: "AAL1_USERPASS",
      azp: "123.client_id",
      selected_roleid: "roleid.test",
      auth_time: Time.zone.now.to_i - 30,
      authentication_assurance_level: "1",
      exp: Time.zone.now.to_i + 3600,
      iat: Time.zone.now.to_i,
      subname: "555057896106",
      nonce: "nonce.test",
      aud: "123.client_id",
      c_hash: "c_hash.test",
      "org.forgerock.openidconnect.ops": "ops.test",
      s_hash: "s_hash.test",
      realm: "/oidc",
      idassurancelevel: "3",
      tokenType: "JWTToken"
    }
  end
  let(:id_token_rs256_jwt) do
    JWT.encode(id_token, server_private_key, "RS256", kid: "key1")
  end

  ## Discovery URL ##################################################
  let(:discovery_url) { "#{issuer}/.well-known/openid-configuration" }
  let(:openid_configuration) do
    {
      issuer:,
      authorization_endpoint:,
      token_endpoint:,
      userinfo_endpoint:,
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: %w[HS256 RS256],
      jwks_uri:,
      response_types_supported: ["code"]
    }
  end

  ## JWKs URI #######################################################
  let(:jwks_uri) { "#{issuer}/connect/jwk_uri" }
  let(:jwks_uri_response) do
    {
      keys: [
        {
          kty: "RSA",
          kid: "key1",
          use: "sig",
          # n: Base64.urlsafe_encode64(server_public_key.n.to_s(2)).tr("=", ""),
          n:
            "qzkiwek8MMBWdnkeoVUKB1GtRubzEauphi17_hwa6UTirWQp1rm9Epxwd4RxPT" \
              "SynNFpLcs980EdShPtuRDVjW4R_Icqe53mF3Y5NIrx2r3IeDy6TH9iC3Ux6A7h" \
              "o3tCb_EZtIgbs40hxHsc4dPzkDKTanbPV8rVFvLftKx19X5RPwmd16lJJTFEZJ" \
              "FtK7L3oD6Qkvk4ZwvfWlSXVnQWYi23cg2DUdoy21_oKOHrYyX6AnltI3YZFJI-" \
              "QKv0cxBMIqa0un5HOa-pqmy0jUduUDGYC6Q37r8TCjP2oqIW6MvjlaQYtd-pAU" \
              "zJdPN5DJcYbq7CeapH8k2yDlRw8qwyfQ",
          # e: Base64.urlsafe_encode64(server_public_key.e.to_s(2)).tr("=", ""),
          e: "AQAB",
          alg: "RS256"
        }
      ]
    }
  end

  # These get stubbed into or used with the described class
  let(:session) { {} }
  let(:env) { {} }
  let(:app) { instance_double(ActionDispatch::Static, call: nil) }

  before do
    # The discovery URL is called to get the openid configuration
    stub_request(:get, discovery_url).to_return_json(body: openid_configuration)

    # Browser gets redirected to the authorization endpoint
    stub_request(:get, authorization_endpoint)

    # The authorization endpoint redirects back to the callback endpoint, and as
    # part of callback phase, the token endpoint is called
    stub_request(:post, token_endpoint).to_return_json(
      body: access_token_response
    )
    # The token endpoint returns the access token and id token, and then the
    # userinfo endpoint is called
    stub_request(:get, userinfo_endpoint).to_return_json(body: userinfo)

    # The jwks_uri is called to get the public key
    stub_request(:get, jwks_uri).to_return_json(body: jwks_uri_response)

    allow(SecureRandom).to receive(:hex).and_return(
      "11111111111111111111111111111111",
      "22222222222222222222222222222222"
    )
  end

  describe "#request_phase" do
    subject(:call_request_phase) do
      strat =
        described_class.new(
          app,
          client_id: "123.client_id",
          secret: "secret",
          redirect_uri: "http://localhost:4000/auth/nhsuk_cis2/callback",
          nhs_environment: :development,
          scope: %i[openid profile email nationalrbacaccess associatedorgs]
        )
      allow(strat).to receive_messages(session:, env:)

      strat.request_phase
    end

    it "calls the discovery url" do
      call_request_phase
      expect(a_request(:get, discovery_url)).to have_been_made.once
    end

    its(:first) { should eq 302 }

    describe "the returned redirect location" do
      subject { URI(call_request_phase.second["location"]) }

      its(:host) { should eq "am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk" }
      its(:port) { should eq 443 }
      its(:query) { should match(/client_id=123.client_id/) }
      its(:query) { should match(/max_age=300/) }
      its(:query) { should match(/nonce=[a-f0-9]{32}/) }
      its(:query) { should match(/response_type=code/) }
      its(:query) { should match(/state=[a-f0-9]{32}/) }

      its(:query) do
        should match(
                 /redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fnhsuk_cis2%2Fcallback/
               )
      end

      its(:query) do
        should match(
                 /scope=openid%20profile%20email%20nationalrbacaccess%20associatedorgs/
               )
      end
    end
  end

  describe "#callback_phase" do
    let(:state) { "11111111111111111111111111111111" }
    let(:request) do
      instance_double(
        Rack::Request,
        env:,
        params: {
          code: "V4IDIO_dDrx2nUNgclv8b465U-g",
          iss:
            "https%3A%2F%2Fam.nhsdev.auth-ptl.cis2.spineservices.nhs.uk%3A443" \
              "%2Fopenam%2Foauth2%2Frealms%2Froot%2Frealms%2Foidc",
          state:,
          client_id: "374150524157.apps.national"
        }.with_indifferent_access
      )
    end

    let(:secret_params) { { secret: "secret" } }
    let(:nhsuk_cis2) do
      described_class
        .new(
          app,
          **{
            client_id: "123.client_id",
            redirect_uri: "http://localhost:4000/auth/nhsuk_cis2/callback",
            nhs_environment: :development,
            scope: %i[openid profile email nationalrbacaccess associatedorgs]
          }.merge(secret_params)
        )
        .tap { allow(_1).to receive_messages(session:, env:, request:) }
    end

    before { nhsuk_cis2.request_phase }

    it "sets the uid in the env" do
      nhsuk_cis2.callback_phase

      expect(env.dig("omniauth.auth", "uid")).to eq "555057896106"
    end

    it "returns the callback return value" do
      allow(app).to receive(:call).and_return({ redirect: "somewhere" })

      expect(nhsuk_cis2.callback_phase).to eq({ redirect: "somewhere" })
    end

    it "includes grant_type=authorization_code when requesting access_token" do
      nhsuk_cis2.callback_phase

      expect(
        a_request(:post, token_endpoint).with do |request|
          request.body =~ /grant_type=authorization_code/
        end
      ).to have_been_made
    end

    context "state is not valid" do
      let(:state) { "22222222222222222222222222222222" }

      it "raises an error" do
        expect { nhsuk_cis2.callback_phase }.to raise_error(
          OmniAuth::Strategies::NhsukCis2::CallbackError,
          /Invalid 'state' parameter/
        )
      end
    end

    context "authentication_type is client_secret" do
      it "includes the client_secret when requesting access_token" do
        nhsuk_cis2.callback_phase

        expect(
          a_request(:post, token_endpoint).with do |request|
            request.body =~ /client_secret=secret/
          end
        ).to have_been_made
      end
    end

    context "authentication_type is private_key_jwt" do
      let(:client_private_key) do
        OpenSSL::PKey::RSA.new(
          File.read(
            Rails.root.join("spec/fixtures/cis2_client_rsa_private.pem")
          )
        )
      end
      let(:secret_params) { { private_key: client_private_key } }

      it "includes client_assertion_type when requesting access_token" do
        nhsuk_cis2.callback_phase

        expect(
          a_request(:post, token_endpoint).with do |request|
            request.body =~
              /client_assertion_type=urn%3Aietf%3Aparams%3Aoauth%3Aclient-assertion-type%3Ajwt-bearer/
          end
        ).to have_been_made
      end

      it "includes client_assertion when requesting access_token" do
        nhsuk_cis2.callback_phase

        expect(
          a_request(:post, token_endpoint).with do |request|
            request.body =~
              /client_assertion=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.*/
          end
        ).to have_been_made
      end
    end
  end
end
