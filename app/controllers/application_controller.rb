# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AuthenticationConcern

  before_action :store_user_location!
  before_action :authenticate_user!
  before_action :set_user_cis2_info
  before_action :set_disable_cache_headers
  before_action :set_header_path
  before_action :set_service_name
  before_action :set_secondary_navigation
  before_action :set_privacy_policy_url
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

  layout "two_thirds"

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_header_path
    @header_path = dashboard_path
  end

  def set_service_name
    @service_name = "Manage vaccinations in schools"
  end

  def set_secondary_navigation
    @show_secondary_navigation = current_user.present?
  end

  def set_disable_cache_headers
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def handle_unprocessable_entity
    render "errors/unprocessable_entity", status: :unprocessable_entity
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referer || root_path, status: :forbidden)
  end

  def set_privacy_policy_url
    @privacy_policy_url =
      current_user&.selected_organisation&.privacy_policy_url
  end
end
