# frozen_string_literal: true

class Sessions::PatientSpecificDirectionsController < ApplicationController
  include PatientSearchFormConcern
  include PatientSpecificDirectionConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    scope = @session.patient_sessions.includes_programmes.includes(:latest_note)
    @eligible_for_bulk_psd_count = patient_sessions_allowed_psd.count
    patient_sessions = @form.apply(scope)
    @pagy, @patient_sessions = pagy(patient_sessions)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def programme
    @session.programmes.first
  end
end
