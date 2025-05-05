# frozen_string_literal: true

class Sessions::ConsentController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_session
  before_action :set_search_form

  layout "full"

  def show
    @statuses = Patient::ConsentStatus.statuses.keys

    scope =
      @session.patient_sessions.includes_programmes.includes(
        :latest_note,
        patient: :consent_statuses
      )

    patient_sessions = @form.apply(scope)
    @pagy, @patient_sessions = pagy(patient_sessions)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
