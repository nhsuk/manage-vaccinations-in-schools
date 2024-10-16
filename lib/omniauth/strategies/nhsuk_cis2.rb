# frozen_string_literal: true

require "omniauth-oauth2"
require "openid_connect"

module OmniAuth
  module Strategies
    class NhsukCis2 < OmniAuth::Strategies::OAuth2
      option :name, "nhsuk_cis2"

      option :http_ssl_min_version, :TLS1_2
      option :nhs_environment, :integration
      option :client_id
      option :scope
      option :private_key
      option :secret
      option :client_options,
             authorization_endpoint: nil,
             token_endpoint: nil,
             userinfo_endpoint: nil,
             redirect_uri: nil

      # TODO: I think these should be plain old options, not "authorize_options"
      # option :authorize_options,
      #        scope: nil,
      #        display: nil,
      #        prompt: nil,
      #        max_age: nil,
      #        ui_locales: nil,
      #        id_token_hint: nil,
      #        login_hint: nil,
      #        acr_values: nil,
      #        claims: nil

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

      def request_phase
        code_verifier = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)
        state = SecureRandom.hex(16)

        client = client_init

        authorization_uri =
          client.authorization_uri(
            scope: options.scope,
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

      def callback_phase
        # Handle the callback phase of the authentication flow
        # ...
      end

      private

      def client_options
        options.client_options
      end

      def client_init
        options.compact!
        client_options.compact!

        init_params = {
          identifier: options.fetch(:client_id),
          authorization_endpoint:
            client_option_or_provider_config(:authorization_endpoint),
          token_endpoint: client_option_or_provider_config(:token_endpoint),
          userinfo_endpoint:
            client_option_or_provider_config(:userinfo_endpoint)
        }

        case options.client_auth_method
        when :private_key_jwt
          init_params[:private_key] = options.fetch(:private_key)
        when :client_secret
          init_params[:secret] = options.fetch(:secret)
        end

        ::OpenIDConnect.http_config do |http_client|
          http_client.ssl.min_version = options.http_ssl_min_version
        end

        ::OpenIDConnect::Client.new(init_params)
      end

      def issuer_for_environment(environment)
        {
          integration:
            "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare"
        }.fetch(environment)
      end

      def provider_config
        @provider_config ||=
          ::OpenIDConnect::Discovery::Provider::Config.discover!(
            issuer_for_environment(options.nhs_environment)
          )
      end

      def client_option_or_provider_config(option)
        client_options.fetch(option, provider_config.as_json[option])
      end
    end
  end
end
