# frozen_string_literal: true

module NHS
  module CIS2
    class << self
      def jwks_fetcher
        ->(options) do
          if options[:kid_not_found] &&
               @cache_last_update < Time.zone.now.to_i - 300
            Rails.logger.info(
              "Invalidating JWK cache. #{options[:kid]} not found from previous cache"
            )
            Rails.cache.delete("cis2:jwks")
          end
          Rails
            .cache
            .fetch("cis2:jwks") do
              @cache_last_update = Time.zone.now.to_i
              jwks_hash = JSON.parse(Faraday.get(jwks_uri).body)
              jwks = JWT::JWK::Set.new(jwks_hash)
              jwks.select! { |key| key[:use] == "sig" }
              jwks
            end
        end
      end

      def openid_configuration
        Rails
          .cache
          .fetch("cis2:openid_configuration", expires_in: 1.day) do
            JSON.parse(
              Faraday
                .new(url: Settings.cis2.issuer)
                .get(".well-known/openid-configuration")
                .body
            )
          end
      end

      def jwks_uri
        openid_configuration&.dig("jwks_uri")
      end
    end
  end
end
