# frozen_string_literal: true

module OmniAuthStrategiesOpenIDConnectPatch
  def access_token
    return @access_token if @access_token

    token_request_params = {
      scope: (options.scope if options.send_scope_to_token_endpoint),
      client_auth_method: options.client_auth_method
    }
    if client_options.key?(:private_key)
      token_request_params[:client_assertion] = generate_client_assertion
    end

    token_request_params[:code_verifier] = params["code_verifier"] ||
      session.delete("omniauth.pkce.verifier") if options.pkce

    @access_token = client.access_token!(token_request_params)
    if configured_response_type == "code"
      verify_id_token!(@access_token.id_token)
    end

    @access_token
  end

  private

  def generate_client_assertion
    payload = {
      iss: client_options.identifier,
      sub: client_options.identifier,
      aud: client_options.token_endpoint,
      jti: SecureRandom.hex(16),
      iat: Time.zone.now.to_i,
      exp: 3.minutes.from_now.to_i
    }
    jwk =
      ::JWT::JWK.new(
        client_options.private_key,
        { alg: "RS256" },
        kid_generator: ::JWT::JWK::Thumbprint
      )

    headers = { kid: jwk.kid, typ: "JWT" }

    ::JWT.encode(payload, client_options.private_key, "RS256", headers)
  end
end
