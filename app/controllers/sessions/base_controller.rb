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
    programmes = @session.programmes

    @programme_statuses =
      Patient::ProgrammeStatus.statuses.keys -
        %w[
          not_eligible
          needs_consent_request_not_scheduled
          needs_consent_request_scheduled
          needs_consent_request_failed
          needs_consent_follow_up_requested
        ]

    due_index = @programme_statuses.find_index("due")

    due_statuses = [
      ("due_injection" unless programmes.all?(&:has_multiple_vaccine_methods?)),
      ("due_nasal" if programmes.any?(&:has_multiple_vaccine_methods?)),
      if programmes.any?(&:vaccine_may_contain_gelatine?)
        "due_injection_without_gelatine"
      end
    ].compact

    @programme_statuses[due_index, 1] = due_statuses
  end
end
