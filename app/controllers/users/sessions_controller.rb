# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include SessionTimeoutConcern
  prepend_before_action :skip_activity_tracking, only: [:time_remaining]

  skip_before_action :authenticate_user!,
                     only: %i[new destroy time_remaining refresh]

  skip_after_action :verify_policy_scoped

  before_action :store_redirect_uri!, only: :new
  before_action :return_unauthorized_if_not_signed_in,
                only: %i[time_remaining refresh]

  layout "one_half"

  def time_remaining
    render json: { time_remaining_seconds: calc_time_remaining_seconds }
  end

  def refresh
    render json: { time_remaining_seconds: calc_time_remaining_seconds }
  end
end
