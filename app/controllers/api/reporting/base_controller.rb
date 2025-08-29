# frozen_string_literal: true

class API::Reporting::BaseController < ActionController::API
  # we need to still include the AuthenticationConcern even though
  # we're not using the authenticate_user! callback, because we call it
  # explicitly after validating the users' JWT in order to use the
  # CIS2 organisation/workgroup validation code
  include AuthenticationConcern
  include ReportingAPI::TokenAuthenticationConcern

  before_action :ensure_reporting_api_feature_enabled
  before_action :authenticate_user_by_jwt!

  private

  def ensure_reporting_api_feature_enabled
    render status: :forbidden and return unless Flipper.enabled?(:reporting_api)
  end
end
