# frozen_string_literal: true

class ErrorsController < ActionController::Base
  include UserSessionLoggingConcern

  before_action :set_assets_name

  layout "two_thirds"

  private

  def set_assets_name
    @assets_name = "application"
  end

  def not_found
    render "not_found", status: :not_found
  end

  def unprocessable_entity
    render "unprocessable_entity", status: :unprocessable_content
  end

  def too_many_requests
    render "too_many_requests", status: :too_many_requests
  end

  def internal_server_error
    render "internal_server_error", status: :internal_server_error
  end
end
