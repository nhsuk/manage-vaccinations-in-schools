# frozen_string_literal: true

module NHS::API
  class << self
    def connection_sans_auth
      Faraday.new(
        base_url,
        headers: {
          apikey:,
          accept: "application/fhir+json",
          "x-request-id" => SecureRandom.uuid
        }
      )
    end

    def connection
      return connection_sans_auth if Settings.nhs_api.disable_authentication

      connection_sans_auth.tap do |conn|
        conn.headers["Authorization"] = "Bearer #{access_token}"
      end
    end

    def access_token
      unless access_token_valid?
        response =
          connection_sans_auth.post(
            token_endpoint,
            {
              grant_type: "client_credentials",
              client_assertion_type:
                "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
              client_assertion: jwt
            }
          )
        @auth_info = JSON.parse(response.body, symbolize_names: true)

        issued_at = @auth_info[:issued_at].to_i
        expires_in = @auth_info[:expires_in].to_i * 1000
        @auth_info[:expires_at] = issued_at + expires_in
      end
      @auth_info[:access_token]
    end

    def access_token_valid?
      return false if @auth_info.blank?

      epoch_msec = Time.zone.now.strftime("%Q").to_i
      safety_msec = 1000 # satety to accomodate connection time
      epoch_msec - safety_msec < @auth_info[:expires_at]
    end

    private

    def jwt
      header = { kid: "mavis-int-1", typ: "JWT", alg: "RS512" }
      payload = {
        iss: apikey,
        sub: apikey,
        aud: token_endpoint,
        jti: SecureRandom.uuid,
        exp: 1.minute.from_now.to_i
      }
      JWT.encode payload, private_key, "RS512", header
    end

    def token_endpoint
      "#{Settings.nhs_api.base_url}/oauth2/token"
    end

    def base_url
      Settings.nhs_api.base_url
    end

    def private_key
      OpenSSL::PKey::RSA.new(Settings.nhs_api.jwt_private_key)
    end

    def apikey
      Settings.nhs_api.apikey
    end
  end
  # end
end
