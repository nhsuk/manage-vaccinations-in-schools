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

    # TODO: Make this more generic.

    due_statuses =
      if programmes.any?(&:flu?) && programmes.any?(&:mmr?)
        %w[due_injection due_nasal due_without_gelatine]
      elsif programmes.any?(&:flu?)
        %w[due_injection due_nasal]
      elsif programmes.any?(&:mmr?)
        %w[due_without_gelatine]
      else
        []
      end

    due_statuses.insert(0, "due") unless programmes.all?(&:flu?)

    @programme_statuses[due_index, 1] = due_statuses
  end
end
