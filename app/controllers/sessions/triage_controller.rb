# frozen_string_literal: true

class Sessions::TriageController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_session
  before_action :set_search_form

  layout "full"

  def show
    @statuses = Patient::TriageStatus.statuses.keys - [:not_required]
    @programmes = @session.programmes

    scope =
      @session
        .patient_sessions
        .includes(patient: :triage_statuses, session: :programmes)
        .in_programmes(@programmes)
        .has_triage_status(@statuses, programme: @programmes)

    patient_sessions = @form.apply(scope, programme: @programmes)
    @pagy, @patient_sessions = pagy(patient_sessions)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
