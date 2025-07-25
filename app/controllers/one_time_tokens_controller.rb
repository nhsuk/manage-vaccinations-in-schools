# frozen_string_literal: true

class OneTimeTokensController < ApplicationController
  protect_from_forgery unless: -> { request.format.json? }
  include TokenAuthenticationConcern

  skip_before_action :authenticate_user!
  before_action :ensure_reporting_app_feature_enabled,
                :authenticate_app_by_client_id!,
                :verify_grant_type!

  def authorize
    skip_policy_scope
    @token = OneTimeToken.find_by!(token: params[:code])
    @token.delete # <- Tokens are one-time use
    json_data = { jwt: jwt(@token) }
    render json: json_data
  rescue ActiveRecord::RecordNotFound
    render json: { errors: "invalid_grant" }, status: :forbidden
  end

  private

  def verify_grant_type!
    unless params["grant_type"] == "authorization_code"
      render json: { error: "unsupported_grant_type" }, status: :bad_request and
        return
    end
  end

  def jwt_payload(token)
    {
      "iat" => Time.current.utc.to_i,
      "data" => {
        "user" => token.user.as_json,
        "cis2_info" => token.cis2_info
      }
    }
  end

  def jwt(token)
    JWT.encode(jwt_payload(token), Settings.mavis_reporting_app.secret, "HS512")
  end

  def ensure_reporting_app_feature_enabled
    render status: :forbidden and return unless Flipper.enabled?(:reporting_app)
  end
end
