# frozen_string_literal: true

module NHS::API
  class << self
    def connection
      return fhir_connection if Settings.nhs_api.disable_authentication

      fhir_connection.tap do |conn|
        conn.headers["Authorization"] = "Bearer #{access_token}"
      end
    end

    def access_token
      fetch_access_token if access_token_expired?

      @auth_info[:access_token]
    end

    def access_token_expired?
      return true if @auth_info.blank?

      # 5 seconds to accommodate connection time
      Time.current > @auth_info[:expires_at] - 5.seconds
    end

    private

    def fetch_access_token
      response =
        oauth_connection.post(
          token_endpoint,
          {
            grant_type: "client_credentials",
            client_assertion_type:
              "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            client_assertion:
          }
        )

      @auth_info = response.body.symbolize_keys

      expires_in = @auth_info[:expires_in].to_i.seconds
      @auth_info[:expires_at] = Time.current + expires_in
    end

    def client_assertion
      header = { kid: "mavis-int-1", typ: "JWT", alg: "RS512" }
      payload = {
        iss: apikey,
        sub: apikey,
        aud: token_endpoint,
        jti: SecureRandom.uuid,
        exp: 3.minutes.from_now.to_i
      }

      JWT.encode(payload, private_key, "RS512", header)
    end

    def oauth_connection
      Faraday.new(headers:) do |f|
        f.request :url_encoded
        f.response :json
        f.response :raise_error
      end
    end

    def fhir_connection
      Faraday.new(
        base_url,
        headers: headers.merge(accept: "application/fhir+json")
      ) do |f|
        f.request :url_encoded
        f.response :json,
                   content_type: %w[application/json application/fhir+json]
        f.response :raise_error
      end
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

    def headers
      { apikey:, x_request_id: SecureRandom.uuid }
    end

    def apikey
      Settings.nhs_api.api_key
    end
  end
end
