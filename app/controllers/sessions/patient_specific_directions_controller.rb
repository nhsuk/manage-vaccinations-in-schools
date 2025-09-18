# frozen_string_literal: true

class Sessions::PatientSpecificDirectionsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_programme
  before_action :set_vaccine
  before_action :set_patient_search_form

  def show
    scope = @session.patients.includes(patient_specific_directions: :programme)

    @eligible_for_bulk_psd_count = patients_allowed_psd.count

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)

    render layout: "full"
  end

  def new
    @eligible_for_bulk_psd_count = patients_allowed_psd.count
  end

  def create
    PatientSpecificDirection.import!(
      psds_to_create,
      on_duplicate_key_ignore: true
    )

    redirect_to session_patient_specific_directions_path(@session),
                flash: {
                  success:
                    "#{"PSD".pluralize(@eligible_for_bulk_psd_count)} added"
                }
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_programme
    # TODO: Handle PSDs in sessions with multiple programmes.
    @programme = @session.programmes.supports_delegation.first
  end

  def set_vaccine
    # TODO: Handle programmes with multiple vaccines.
    @vaccine = @programme.vaccines.nasal.first
  end

  def psds_to_create
    patients_allowed_psd.map do |patient|
      PatientSpecificDirection.new(
        academic_year: @session.academic_year,
        created_by: current_user,
        delivery_site: "nose",
        patient:,
        programme: @programme,
        team: current_team,
        vaccine: @vaccine,
        vaccine_method: "nasal"
      )
    end
  end

  def patients_allowed_psd
    @patients_allowed_psd ||=
      @session
        .patients
        .has_consent_status(
          "given",
          programme: @programme,
          academic_year: @session.academic_year,
          vaccine_method: "nasal"
        )
        .has_triage_status(
          "not_required",
          programme: @programme,
          academic_year: @session.academic_year
        )
        .without_patient_specific_direction(
          programme: @programme,
          academic_year: @session.academic_year,
          team: current_team
        )
  end
end
