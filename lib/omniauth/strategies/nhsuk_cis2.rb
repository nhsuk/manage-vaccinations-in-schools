# frozen_string_literal: true

require "omniauth-oauth2"
require "openid_connect"

module OmniAuth
  module Strategies
    class NhsukCis2 < OmniAuth::Strategies::OAuth2
      option :name, "nhsuk_cis2"

      option :client_options,
             {
               identifier: Settings.cis2.client_id,
               private_key: OpenSSL::PKey::RSA.generate(2048),
               # secret: ENV.fetch("NHSUK_CIS2_PRIVATE_KEY"),
               host: Settings.cis2.host,
               authorization_endpoint:
                 "/openam/oauth2/realms/root/realms/oidc/authorize",
               token_endpoint:
                 "/openam/oauth2/realms/root/realms/oidc/access_token",
               userinfo_endpoint:
                 "/openam/oauth2/realms/root/realms/oidc/userinfo"
             }

      option :authorize_options,
             %i[
               scope
               display
               prompt
               max_age
               ui_locales
               id_token_hint
               login_hint
               acr_values
               claims
             ]

      uid { raw_info["sub"] }

      info do
        {
          name: raw_info["name"],
          email: raw_info["email"]
          # Add additional user information as needed
        }
      end

      def raw_info
        @raw_info ||= access_token.userinfo!.raw_attributes
      end

      def callback_phase
        # Handle the callback phase of the authentication flow
        # ...
      end

      def request_phase
        code_verifier = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        state = SecureRandom.hex(16)

        client = ::OpenIDConnect::Client.new(options.client_options)

        authorization_uri =
          client.authorization_uri(
            scope: options.authorize_options[:scope],
            nonce: nonce,
            state: state,
            code_challenge:
              Base64.urlsafe_encode64(
                OpenSSL::Digest::SHA256.digest(code_verifier)
              ),
            code_challenge_method: :S256
          )

        redirect authorization_uri.to_s
      end

      # Add any other necessary methods or configurations
    end
  end
end
