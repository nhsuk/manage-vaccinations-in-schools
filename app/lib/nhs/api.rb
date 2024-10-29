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
      fetch_access_token unless access_token_valid?

      @auth_info[:access_token]
    end

    def access_token_valid?
      return false if @auth_info.blank?

      now_msec = Time.current.strftime("%Q").to_i
      safety_msec = 5000 # safety to accommodate connection time
      now_msec + safety_msec < @auth_info[:expires_at]
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

      issued_at = @auth_info[:issued_at].to_i # milliseconds
      expires_in = @auth_info[:expires_in].to_i * 1000
      @auth_info[:expires_at] = issued_at + expires_in
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
      Settings.nhs_api.apikey
    end
  end
end
