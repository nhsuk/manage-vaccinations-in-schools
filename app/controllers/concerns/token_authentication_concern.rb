# frozen_string_literal: true

module TokenAuthenticationConcern
  extend ActiveSupport::Concern

  included do
    private

    def token_error!(token)
      if token.blank?
        render json: { errors: "Unauthorized" }, status: :unauthorized and
          return
      else
        render json: { errors: "Forbidden" }, status: :forbidden and return
      end
    end

    def authenticate_app_by_token!
      possible_tokens = []
      # auth_token_by_param means tokens could appear in logs => it's for dev environments only
      # hence making it controlled by feature flag
      possible_tokens << params[:auth] if Flipper.enabled?(:auth_token_by_param)
      # auth_token_by_header is safer, hence having its own feature flag
      if Flipper.enabled?(:auth_token_by_header)
        possible_tokens << request.headers["Authorization"]
      end

      token = possible_tokens.find { it == Settings.mavis_reporting_app.secret }
      token_error!(token) unless token
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
            id: data["user"]["id"],
            session_token: data["user"]["session_token"],
            pwd_auth_session_token: data["user"]["pwd_auth_session_token"]
          )
        if @current_user
          session["user"] = data["user"]
          session["cis2_info"] = data["cis2_info"]
          authenticate_user!
        else
          session.clear
          Rails.logger.warn "Couldn't find user id #{data["user"]["id"]} with given session_token and pwd_auth_session_token"
          token_error!(jwt)
        end
      end
    rescue JWT::DecodeError, NoMethodError
      Rails.logger.warn "invalid JWT"
      token_error!(jwt)
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
