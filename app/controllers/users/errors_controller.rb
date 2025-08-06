# frozen_string_literal: true

class Users::ErrorsController < ::ApplicationController
  skip_before_action :store_user_location!
  skip_before_action :authenticate_user!
  skip_before_action :ensure_team_is_selected
  skip_after_action :verify_policy_scoped

  before_action :set_cis2_info

  def organisation_not_found
    if @cis2_info.present?
      render status: :not_found
    else
      redirect_to root_path
    end
  end

  def workgroup_not_found
    if @cis2_info.present?
      render status: :not_found
    else
      redirect_to root_path
    end
  end

  def role_not_found
    if @cis2_info.present?
      render status: :not_found
    else
      redirect_to root_path
    end
  end

  private

  def set_cis2_info
    @cis2_info = CIS2Info.new(request_session: session)
  end
end
