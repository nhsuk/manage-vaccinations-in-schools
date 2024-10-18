# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AuthenticationConcern

  before_action :store_user_location!
  before_action :authenticate_user!
  before_action :set_user_sso_session
  before_action :set_disable_cache_headers
  before_action :set_header_path
  before_action :set_service_name
  before_action :set_secondary_navigation
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

  def set_user_sso_session
    return unless Flipper.enabled?(:sso_session) && current_user

    current_user.sso_session = session["cis2_info"]
  end
end
