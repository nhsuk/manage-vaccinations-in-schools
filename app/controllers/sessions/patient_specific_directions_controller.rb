# frozen_string_literal: true

class Sessions::PatientSpecificDirectionsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

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
  end

  def create
    ActiveRecord::Base.transaction do
      PatientSpecificDirection.import!(
        psds_to_create,
        on_duplicate_key_ignore: true
      )
    end

    redirect_to session_patient_specific_directions_path(@session),
                flash: {
                  success: "PSDs added"
                }
  end

  def bulk_add
    @eligible_for_bulk_psd_count = patient_sessions_allowed_psd.count
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
        patient_id: patient_session.patient_id,
        programme_id: programme.id,
        vaccine_id: programme.vaccines.first.id,
        created_by_user_id: current_user.id,
        vaccine_method: :nasal,
        delivery_site: :nose
      )
    end
  end

  def patient_sessions_allowed_psd
    @patient_sessions_allowed_psd ||=
      @session
        .patient_sessions
        .has_consent_status(:given, programme:)
        .without_patient_specific_direction(programme:)
  end
end
