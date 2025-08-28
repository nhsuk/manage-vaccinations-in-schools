# frozen_string_literal: true

class Sessions::PatientSpecificDirectionsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  def show
    scope =
      @session.patient_sessions.includes_programmes.includes(
        patient: {
          patient_specific_directions: :programme
        }
      )
    @eligible_for_bulk_psd_count = patient_sessions_allowed_psd.count
    patient_sessions = @form.apply(scope)
    @pagy, @patient_sessions = pagy(patient_sessions)

    render layout: "full"
  end

  def new
    @eligible_for_bulk_psd_count = patient_sessions_allowed_psd.count
  end

  def create
    PatientSpecificDirection.import!(
      psds_to_create,
      on_duplicate_key_ignore: true
    )

    redirect_to session_patient_specific_directions_path(@session),
                flash: {
                  success: "PSDs added"
                }
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def programme
    @session.programmes.includes(:vaccines).first
  end

  def psds_to_create
    patient_sessions_allowed_psd.map do |patient_session|
      PatientSpecificDirection.new(
        academic_year: @session.academic_year,
        created_by_user_id: current_user.id,
        delivery_site: "nose",
        patient_id: patient_session.patient_id,
        programme_id: programme.id,
        vaccine_id: programme.vaccines.find(&:nasal?).id,
        vaccine_method: "nasal"
      )
    end
  end

  def patient_sessions_allowed_psd
    @patient_sessions_allowed_psd ||=
      @session
        .patient_sessions
        .has_consent_status(:given, programme:)
        .has_triage_status(:not_required, programme:)
        .without_patient_specific_direction(programme:)
  end
end
