class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :store_user_location!
  before_action :authenticate_user!
  before_action :set_disable_cache_headers
  before_action :set_header_path
  before_action :set_service_name
  before_action :set_phase_banner_text

  class UnprocessableEntity < StandardError
  end

  unless Rails.configuration.consider_all_requests_local
    rescue_from UnprocessableEntity, with: :handle_unprocessable_entity
  end

  if Flipper.enabled? :basic_auth
    http_basic_authenticate_with name: Settings.support_username,
                                 password: Settings.support_password,
                                 message:
                                   "THIS IS NOT A PRODUCTION NHS.UK SERVICE"
  end

  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)

  private

  def set_header_path
    @header_path = dashboard_path
  end

  def set_service_name
    @service_name = "Manage vaccinations in schools"
  end

  def set_phase_banner_text
    @phase_banner_text =
      "This is a pilot service. Do not use it to make clinical decisions."
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
end
