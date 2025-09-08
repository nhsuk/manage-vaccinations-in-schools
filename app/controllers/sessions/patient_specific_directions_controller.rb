# frozen_string_literal: true

class Sessions::PatientSpecificDirectionsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_programme
  before_action :set_vaccine
  before_action :set_patient_search_form

  def show
    scope =
      @session.patient_locations.includes_programmes.includes(
        patient: {
          patient_specific_directions: :programme
        }
      )
    @eligible_for_bulk_psd_count = patient_locations_allowed_psd.count
    patient_locations = @form.apply(scope)
    @pagy, @patient_locations = pagy(patient_locations)

    render layout: "full"
  end

  def new
    @eligible_for_bulk_psd_count = patient_locations_allowed_psd.count
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
    patient_locations_allowed_psd.map do |patient_location|
      PatientSpecificDirection.new(
        academic_year: @session.academic_year,
        created_by: current_user,
        delivery_site: "nose",
        patient_id: patient_location.patient_id,
        programme: @programme,
        team: current_team,
        vaccine: @vaccine,
        vaccine_method: "nasal"
      )
    end
  end

  def patient_locations_allowed_psd
    @patient_locations_allowed_psd ||=
      @session
        .patient_locations
        .has_consent_status(
          "given",
          programme: @programme,
          vaccine_method: "nasal"
        )
        .has_triage_status("not_required", programme: @programme)
        .without_patient_specific_direction(
          programme: @programme,
          team: current_team
        )
  end
end
