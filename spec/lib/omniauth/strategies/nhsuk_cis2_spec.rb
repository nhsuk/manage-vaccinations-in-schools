# frozen_string_literal: true

require_relative Rails.root.join("lib/omniauth/strategies/nhsuk_cis2")

describe ::OmniAuth::Strategies::NhsukCis2 do
  describe "#request_phase" do
    it "redirects to the correct authorization uri" do
      stub_request(
        :get,
        "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk" \
          "/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare/.well-known/openid-configuration"
      ).to_return_json(
        body: {
          issuer:
            "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare",
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
            "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare/connect/jwk_uri",
          response_types_supported: ["code"]
        }
      )
      stub_request(
        :get,
        "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk" \
          "/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare/authorize"
      )

      strat =
        ::OmniAuth::Strategies::NhsukCis2.new(
          :nhsuk_cis2,
          client_id: "123",
          redirect_uri: "http://localhost:4000/auth/nhsuk_cis2/callback",
          nhs_environment: :integration,
          scope: %i[openid profile email nationalrbacaccess associatedorgs]
        )
      # allow(strat).to receive(:redirect)
      allow(SecureRandom).to receive(:hex).and_return(
        "11111111111111111111111111111111",
        "22222222222222222222222222222222"
      )

      response = strat.request_phase

      expect(
        a_request(
          :get,
          "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk" \
            "/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare/.well-known/openid-configuration"
        )
      ).to have_been_made.once

      query = {
        client_id: "123",
        max_age: 300,
        nonce: "11111111111111111111111111111111",
        redirect_uri: "http://localhost:4000/auth/nhsuk_cis2/callback",
        response_type: "code",
        scope: "openid profile email nationalrbacaccess associatedorgs",
        state: "22222222222222222222222222222222"
      }.to_query.gsub("+", "%20") # CGI.escape does not replace spaces with %20

      expect(response.first).to eq 302
      expect(
        response.second["location"]
      ).to eq "http://localhost:4000/oidc/realms/test/authorize?#{query}"
    end
  end
end
