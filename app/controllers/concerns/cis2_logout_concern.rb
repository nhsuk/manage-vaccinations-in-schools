# frozen_string_literal: true

module CIS2LogoutConcern
  extend ActiveSupport::Concern

  included do
    private

    def validate_logout_token(token)
      header = JWT.decode(token, nil, false).second
      return false if header["alg"] != "RS256"

      jwt =
        JWT.decode(
          token,
          nil,
          true,
          { algorithms: ["RS256"], jwks: cis2_jwks_fetcher }
        )
      claims = jwt.first

      backchannel_event = "http://schemas.openid.net/event/backchannel-logout"
      return false unless claims.dig("events", backchannel_event)
      return false if claims["iss"] != Settings.cis2.issuer
      return false if claims["aud"] != Settings.cis2.client_id
      return false if claims["iat"] < Time.zone.now.to_i - 300
      return false if claims["iat"] > Time.zone.now.to_i
      return false if claims["exp"] && claims["exp"] < Time.zone.now.to_i

      @user = User.find_by(uid: claims["sub"])
      return false if @user.blank?
      return false if @user.current_sign_in_at.blank?
      return false if claims["iat"] < @user.current_sign_in_at.to_i

      true
    rescue JWT::DecodeError
      false
    end

    def cis2_jwks_fetcher
      ->(options) do
        if options[:kid_not_found] &&
             @cache_last_update < Time.zone.now.to_i - 300
          logger.info(
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
            jwks.select { |key| key[:use] == "sig" }
          end
      end
    end

    def cis2_openid_configuration
      @cis2_openid_configuration ||=
        JSON.parse(
          Faraday
            .new(url: Settings.cis2.issuer)
            .get(".well-known/openid-configuration")
            .body
        )
    end

    def jwks_uri
      cis2_openid_configuration["jwks_uri"]
    end
  end
end
