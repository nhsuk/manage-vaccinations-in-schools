# frozen_string_literal: true

class Sessions::PatientsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    @statuses = Patient::VaccinationStatus.statuses.keys - %w[not_eligible]

    scope =
      @session.patients.includes(
        :consent_statuses,
        :triage_statuses,
        :vaccination_statuses,
        notes: :created_by
      )

    patients = @form.apply(scope)

    @pagy, @patients =
      patients.is_a?(Array) ? pagy_array(patients) : pagy(patients)
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:location_programme_year_groups).find_by!(
        slug: params[:session_slug]
      )
  end
end
