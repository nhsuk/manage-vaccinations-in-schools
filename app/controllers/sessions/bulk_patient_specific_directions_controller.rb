# frozen_string_literal: true

class Sessions::BulkPatientSpecificDirectionsController < ApplicationController
  include PatientSpecificDirectionConcern

  before_action :set_session

  def show
    @eligible_for_bulk_psd_count = patient_sessions_allowed_psd.count
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

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
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
        delivery_site: :nose,
        full_dose: true
      )
    end
  end

  def programme
    @session.programmes.includes(:vaccines).first
  end
end
