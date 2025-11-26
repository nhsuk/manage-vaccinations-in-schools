# frozen_string_literal: true

class Sessions::BaseController < ApplicationController
  before_action :set_session
  before_action :set_programme_statuses

  private

  def set_session
    @session =
      policy_scope(Session).includes(:session_programme_year_groups).find_by!(
        slug: params[:session_slug]
      )
  end

  def set_programme_statuses
    @programme_statuses =
      Patient::ProgrammeStatus.statuses.keys -
        %w[
          not_eligible
          needs_consent_request_not_scheduled
          needs_consent_request_scheduled
          needs_consent_request_failed
          needs_consent_follow_up_requested
        ]
  end
end
