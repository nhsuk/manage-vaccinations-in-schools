# frozen_string_literal: true

class NotificationsController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate

  def create
    delivery_id = params.require(:id)
    delivery_status = params.require(:status).underscore

    if (notify_log_entry = NotifyLogEntry.find_by(delivery_id:))
      notify_log_entry.update!(delivery_status:)
      head :no_content
    else
      head :not_found
    end
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(
        token,
        Settings.govuk_notify.callback_bearer_token
      )
    end
  end
end
