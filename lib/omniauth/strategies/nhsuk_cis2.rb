# frozen_string_literal: true

module OmniAuth
  module Strategies
    class NhsukCis2
      include OmniAuth::Strategy

      option :name, "nhsuk_cis2"

      option :http_ssl_min_version, :TLS1_2
      option :nhs_environment, :integration
      option :client_id
      option :scope, [:openid]
      option :private_key
      option :secret
      option :max_age, 300
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

      uid { user_data["sub"] }

      info do
        {
          name: user_data["name"],
          email: user_data["email"]
          # Add additional user information as needed
        }
      end

      extra { { raw_info: user_data } }

      def initialize(*args)
        super

        ::OpenIDConnect.http_config do |http_client|
          http_client.ssl.min_version = options.http_ssl_min_version
        end

        validate_options!
      end

      def raw_info
        @raw_info ||= access_token.userinfo!.raw_attributes
      end

      def access_token
        @access_token ||=
          client.access_token!(
            # NOTE: this triggers auto JWT assertion generation for client auth
            #       using `Client#secret` or `Client#private_key` with auto signature
            #       algorithm detection (ES256, RSA256 or HS256).
            # :jwt_bearer
            authentication_type
          )
      end

      def request_phase
        # TODO: nonce needs to be saved to validate the ID token
        session["nhsuk_cis2.state"] = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)

        params = {
          scope: options.scope.join(" "),
          nonce:,
          max_age: options[:max_age],
          state: session["nhsuk_cis2.state"]
        }
        authorization_uri = client.authorization_uri(**params)
        Rails.logger.info "Authorization URI: #{authorization_uri}"

        redirect authorization_uri.to_s
      end

      def user_data
        @user_data =
          access_token.userinfo!.raw_attributes.tap do
            if access_token.id_token
              _1.merge!(
                ::OpenIDConnect::ResponseObject::IdToken.decode(
                  access_token.id_token,
                  provider_config
                ).raw_attributes
              )
            end
          end
      end

      def callback_phase
        client.authorization_code = request.params["code"]
        binding.irb
        env["omniauth.auth"] = AuthHash.new(
          provider: name,
          uid: user_data["sub"],
          info: {
            name: user_data["name"],
            email: user_data["email"]
          },
          extra: {
            raw_info: user_data
          }
        )
        # userinfo = access_token.userinfo!

        # TODO: All the verifications
        #       - state
        #       - nonce?
        #       - all the stuff in verify_cis2_response

        super
      end

      private

      def client
        @client ||= ::OpenIDConnect::Client.new(client_params)
      end

      def client_params
        params = {
          identifier: options.fetch(:client_id),
          authorization_endpoint:
            client_option_or_provider_config(:authorization_endpoint),
          token_endpoint: client_option_or_provider_config(:token_endpoint),
          userinfo_endpoint:
            client_option_or_provider_config(:userinfo_endpoint),
          redirect_uri: options.fetch(:redirect_uri)
        }

        if options.secret.present?
          params[:secret] = options.fetch(:secret)
        elsif options.private_key.present?
          params[:private_key] = options.fetch(:private_key)
        end

        params
      end

      def client_options
        options.client_options
      end

      def authentication_type
        if options.secret.present?
          :client_secret
        elsif options.private_key.present?
          :private_key_jwt
        end
      end

      def validate_options!
        options.compact!
        client_options.compact!

        if options.secret.present? && options.private_key.present?
          raise ArgumentError,
                "only one of client_secret or private_key can be set"
        elsif options.secret.blank? && options.private_key.blank?
          raise ArgumentError, "client_secret or private_key must be set"
        end
      end

      def issuer_for_environment(environment)
        {
          development:
            "https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc",
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
