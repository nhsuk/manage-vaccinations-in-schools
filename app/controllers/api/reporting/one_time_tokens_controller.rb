# frozen_string_literal: true

class API::Reporting::OneTimeTokensController < API::Reporting::BaseController
  # skip_before_action :authenticate_user!
  before_action :ensure_reporting_api_feature_enabled,
                :authenticate_app_by_client_id!,
                :verify_grant_type!

  def authorize
    @token = ReportingAPI::OneTimeToken.find_by!(token: params[:code])
    @token.delete # <- Tokens are one-time use

    user = @token.user
    display_name = user.full_name
    display_name +=
      " (#{user.role_description})" if user.role_description.present?

    json_data = {
      jwt: @token.to_jwt,
      user_nav: {
        items: [
          { text: display_name, icon: true },
          { href: logout_path, text: "Log out" }
        ]
      }
    }
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
end
