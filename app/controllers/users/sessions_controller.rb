# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
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

  private

  def calc_time_remaining_seconds
    last_activity = session.dig("warden.user.user.session", "last_request_at")
    if last_activity.class != Integer
      raise "Last request at value from session is not an integer"
    end
    expires_at = last_activity + Devise.timeout_in
    [(expires_at - Time.current.to_i), 0].max
  end

  def return_unauthorized_if_not_signed_in
    unless user_signed_in?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def skip_activity_tracking
    request.env["devise.skip_trackable"] = true
  end
end
