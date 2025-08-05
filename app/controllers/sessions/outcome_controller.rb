# frozen_string_literal: true

class Sessions::OutcomeController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    @statuses = PatientSession::SessionStatus.statuses.keys

    scope =
      @session.patient_sessions.includes_programmes.includes(
        :latest_note,
        :session_statuses
      )

    patient_sessions = @form.apply(scope)
    @pagy, @patient_sessions = pagy(patient_sessions)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
