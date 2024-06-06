class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :store_user_location!
  before_action :authenticate_user!
  before_action :set_disable_cache_headers
  before_action :set_header_path
  before_action :set_service_name
  before_action :authenticate_basic

  after_action :verify_policy_scoped,
               if: -> { Rails.env.development? || Rails.env.test? }

  class UnprocessableEntity < StandardError
  end

  unless Rails.configuration.consider_all_requests_local
    rescue_from UnprocessableEntity, with: :handle_unprocessable_entity
  end

  FLIPPER_INITIALIZERS[:basic_auth].call unless Flipper.exist? :basic_auth

  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)

  private

  def set_header_path
    @header_path = dashboard_path
  end

  def set_service_name
    @service_name = "Manage vaccinations in schools"
  end

  def set_disable_cache_headers
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def handle_unprocessable_entity
    render "errors/unprocessable_entity", status: :unprocessable_entity
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? &&
      !request.xhr? && !turbo_frame_request?
  end

  def store_user_location!
    return unless user_signed_in?
    return unless storable_location?

    store_location_for(:user, request.fullpath)
  end

  def authenticate_basic
    if Flipper.enabled? :basic_auth
      authenticated =
        authenticate_with_http_basic do |username, password|
          username == Settings.support_username &&
            password == Settings.support_password
        end

      unless authenticated
        request_http_basic_authentication "Application", <<~MESSAGE
        Access is currently restricted to authorised users only.
      MESSAGE
      end
    end
  end
end
