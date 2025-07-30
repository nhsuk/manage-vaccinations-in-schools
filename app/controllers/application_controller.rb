# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AuthenticationConcern

  before_action :store_user_location!
  before_action :authenticate_user!
  before_action :set_selected_organisation
  before_action :set_user_cis2_info
  before_action :set_disable_cache_headers
  before_action :set_header_path
  before_action :set_service_name
  before_action :set_theme_colour
  before_action :set_service_guide_url
  before_action :set_show_navigation
  before_action :set_privacy_policy_url
  before_action :set_sentry_user
  before_action :authenticate_basic

  after_action :verify_policy_scoped, if: -> { Rails.env.local? }

  class UnprocessableEntity < StandardError
  end

  unless Rails.configuration.consider_all_requests_local
    rescue_from UnprocessableEntity, with: :handle_unprocessable_entity
  end

  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)

  layout "two_thirds"

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_selected_organisation
    return if Settings.cis2.enabled
    return unless current_user
    return if session["cis2_info"].present?

    redirect_to new_users_organisations_path
  end

  def set_header_path
    @header_path = dashboard_path
  end

  def set_service_name
    @service_name = "Manage vaccinations in schools"
  end

  def set_theme_colour
    @theme_colour = HostingEnvironment.theme_colour
  end

  def set_show_navigation
    @show_navigation = current_user.present?
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
    redirect_back_or_to root_path, status: :forbidden, allow_other_host: false
  end

  def set_service_guide_url
    @service_guide_url = "https://guide.manage-vaccinations-in-schools.nhs.uk"
  end

  def set_privacy_policy_url
    @privacy_policy_url = nil
  end

  def set_sentry_user
    Sentry.set_user(id: current_user&.id)
  end
end
