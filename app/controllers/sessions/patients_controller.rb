# frozen_string_literal: true

class Sessions::PatientsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    @statuses = Patient::VaccinationStatus.statuses.keys

    scope =
      @session.patient_locations.includes(
        patient: [:vaccination_statuses, { notes: :created_by }]
      )

    patient_locations = @form.apply(scope)
    @pagy, @patient_locations = pagy(patient_locations)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
