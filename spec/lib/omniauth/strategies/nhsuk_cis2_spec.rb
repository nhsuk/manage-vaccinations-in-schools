# frozen_string_literal: true

require_relative Rails.root.join("lib/omniauth/strategies/nhsuk_cis2")

describe ::OmniAuth::Strategies::NhsukCis2 do
  let(:session) { {} }

  describe "#request_phase" do
    let(:openid_configuration) do
      {
        issuer:
          "https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc",
        authorization_endpoint:
          "http://localhost:4000/oidc/realms/test/authorize",
        token_endpoint: "http://localhost:4000/oidc/realms/test/token",
        userinfo_endpoint: "http://localhost:4000/oidc/realms/test/userinfo",
        subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: %w[
          PS384
          ES384
          RS384
          HS256
          HS512
          ES256
          RS256
          HS384
          ES512
          PS256
          PS512
          RS512
        ],
        jwks_uri:
          "https://am.nhsidev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc/connect/jwk_uri",
        response_types_supported: ["code"]
      }
    end
    let(:cis2_host) { "https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk" }
    let(:discovery_url) do
      "#{cis2_host}/openam/oauth2/realms/root/realms/oidc/.well-known/openid-configuration"
    end
    let(:authorization_url) do
      "#{cis2_host}/openam/oauth2/realms/root/realms/oidc/authorize"
    end

    before do
      stub_request(:get, discovery_url).to_return_json(
        body: openid_configuration
      )

      stub_request(:get, authorization_url)

      allow(SecureRandom).to receive(:hex).and_return(
        "11111111111111111111111111111111",
        "22222222222222222222222222222222"
      )
    end

    subject(:call_request_phase) do
      strat =
        described_class.new(
          :nhsuk_cis2,
          client_id: "123",
          secret: "secret",
          redirect_uri: "http://localhost:4000/auth/nhsuk_cis2/callback",
          nhs_environment: :development,
          scope: %i[openid profile email nationalrbacaccess associatedorgs]
        )
      allow(strat).to receive(:session).and_return({})

      strat.request_phase
    end

    it "calls the discovery url" do
      call_request_phase
      expect(a_request(:get, discovery_url)).to have_been_made.once
    end

    it "redirects to the correct authorization uri" do
      query = {
        client_id: "123",
        max_age: 300,
        nonce: "22222222222222222222222222222222",
        redirect_uri: "http://localhost:4000/auth/nhsuk_cis2/callback",
        response_type: "code",
        scope: "openid profile email nationalrbacaccess associatedorgs",
        state: "11111111111111111111111111111111"
      }.to_query.gsub("+", "%20") # CGI.escape does not replace spaces with %20

      response = call_request_phase
      expect(response.first).to eq 302
      expect(
        response.second["location"]
      ).to eq "http://localhost:4000/oidc/realms/test/authorize?#{query}"
    end
  end
end
