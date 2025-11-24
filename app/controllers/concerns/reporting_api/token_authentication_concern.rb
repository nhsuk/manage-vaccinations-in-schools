# frozen_string_literal: true

module ReportingAPI::TokenAuthenticationConcern
  extend ActiveSupport::Concern

  included do
    private

    def client_id_error!(token)
      if token.blank?
        render json: { errors: "invalid_request" }, status: :unauthorized
      else
        render json: { errors: "unauthorized_client" }, status: :forbidden
      end
    end

    def authenticate_app_by_client_id!
      if Flipper.enabled?(:reporting_api)
        # ...as per the spec at https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
        given_client_id = params.fetch("client_id", nil)
        unless given_client_id == Settings.reporting_api.client_app.client_id
          client_id_error!(given_client_id)
        end
      end
    end

    def jwt_if_given
      params[:jwt] ||
        request.headers["Authorization"]&.gsub(/(Bearer\s+)?([:alnum:]*)/, '\2')
    end

    def authenticate_user_by_jwt!
      jwt = jwt_if_given
      jwt_info = decode_jwt!(jwt)
      if jwt_info
        data = jwt_info.first["data"]
        @current_user =
          User.find_by(
            data.fetch("user", {}).slice(
              "id",
              "session_token",
              "reporting_api_session_token"
            )
          )
        if @current_user
          session["user"] = data["user"]
          session["cis2_info"] = data["cis2_info"]
          authenticate_user!
          touch_sessions(@current_user)
        else
          session.clear
          client_id_error!(jwt)
          Rails.logger.warn "Couldn't find user id #{data.dig("user", "id")} with tokens"
        end
      end
    rescue JWT::DecodeError, NoMethodError
      Rails.logger.warn "invalid JWT"
      client_id_error!(jwt)
    end
  end

  def decode_jwt!(jwt)
    if jwt
      JWT.decode(
        jwt,
        Settings.reporting_api.client_app.secret,
        true,
        { algorithm: ReportingAPI::OneTimeToken::JWT_SIGNING_ALGORITHM }
      )
    end
  end

  def touch_sessions(user)
    sessions =
      ActiveRecord::SessionStore::Session.where(
        "(data #>> '{}'::text[])::jsonb -> 'value' -> 'warden.user.user.key' -> 0 @> ?::jsonb",
        [user.id].to_json
      )

    now = Time.zone.now.utc.to_i
    sessions.each do
      it.data["warden.user.user.session"]["last_request_at"] = now
      it.save!
    end
  end
end
