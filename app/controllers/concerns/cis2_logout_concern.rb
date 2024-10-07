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
          { algorithms: ["RS256"], jwks: NHS::CIS2.jwks_fetcher }
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
  end
end
