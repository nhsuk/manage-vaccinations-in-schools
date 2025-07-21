# frozen_string_literal: true

module TokenAuthenticationConcern
  extend ActiveSupport::Concern

  included do
    private

    def client_id_error!(token)
      if token.blank?
        render json: { errors: "invalid_request" }, status: :unauthorized and return
      else
        render json: { errors: "unauthorized_client" }, status: :forbidden and return
      end
    end

    def authenticate_app_by_client_id!
      possible_clients = []

      if Flipper.enabled?(:reporting_app)
        # ...as per the spec at https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3
        given_client_id = params.fetch("client_id", nil)
        client_id_error!(given_client_id) unless given_client_id == Settings.mavis_reporting_app.client_id
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
            id: data.dig("user", "id"),
            session_token: data.dig("user", "session_token"),
            reporting_app_session_token: data.dig("user", "reporting_app_session_token")
          )
        if @current_user
          session["user"] = data["user"]
          session["cis2_info"] = data["cis2_info"]
          authenticate_user!
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
        Settings.mavis_reporting_app.secret,
        true,
        { algorithm: "HS512" }
      )
    end
  end
end
