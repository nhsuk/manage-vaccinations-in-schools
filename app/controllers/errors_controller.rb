# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped
  skip_before_action :store_user_location!, only: :team_not_found

  layout "two_thirds"

  def not_found
    render "not_found", status: :not_found
  end

  def unprocessable_entity
    render "unprocessable_entity", status: :unprocessable_entity
  end

  def too_many_requests
    render "too_many_requests", status: :too_many_requests
  end

  def internal_server_error
    render "internal_server_error", status: :internal_server_error
  end

  def team_not_found
    if flash.key? :cis2_info
      @cis2_info = flash[:cis2_info].with_indifferent_access
      render status: :not_found
    else
      redirect_to root_path
    end
  end
end
