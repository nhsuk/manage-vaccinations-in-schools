# frozen_string_literal: true

module SessionTimeoutConcern
  extend ActiveSupport::Concern

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
