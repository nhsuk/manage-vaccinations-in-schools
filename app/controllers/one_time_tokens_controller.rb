# frozen_string_literal: true

class OneTimeTokensController < ApplicationController
  include TokenAuthenticationConcern

  skip_before_action :authenticate_user!
  before_action :authenticate_app_by_token!

  def verify
    skip_policy_scope
    @token = OneTimeToken.find_by!(token: params[:token])
    @token.delete # <- Tokens are one-time use
    json_data =
      @token.as_json.merge({ user: @token.user.as_json, jwt: jwt(@token) })
    render json: json_data
  rescue ActiveRecord::RecordNotFound
    render json: { errors: "Not found" }, status: :not_found
  end

  private

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
end
