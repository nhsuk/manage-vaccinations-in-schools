# frozen_string_literal: true

describe "JWKS endpoint" do
  scenario "Getting keys" do
    when_we_retrieve_the_jwks
    then_i_see_a_key
  end

  def when_we_retrieve_the_jwks
    visit "/oidc/jwks"
  end

  def then_i_see_a_key
    jwks = JSON.parse(page.body)
    keys = jwks["keys"]

    expect(keys.count).to eq 2

    cis2_jwk = get_jwk_for_key(Settings.cis2.private_key, keys, alg: "RS256")
    expect(cis2_jwk).to be_present
    expect(cis2_jwk["alg"]).to eq "RS256"

    nhs_api_jwk =
      get_jwk_for_key(Settings.nhs_api.jwt_private_key, keys, alg: "RS512")
    expect(nhs_api_jwk).to be_present
    expect(nhs_api_jwk["alg"]).to eq "RS512"
  end

  def get_jwk_for_key(pem, keys, alg)
    key = OpenSSL::PKey::RSA.new(pem)
    kid = JWT::JWK.new(key, { alg: }, kid_generator: ::JWT::JWK::Thumbprint).kid
    keys.find { _1["kid"] == kid }
  end
end
