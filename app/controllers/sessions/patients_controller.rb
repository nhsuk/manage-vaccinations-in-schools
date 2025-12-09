# frozen_string_literal: true

class Sessions::PatientsController < Sessions::BaseController
  include PatientSearchFormConcern

  before_action :set_patient_search_form
  before_action :set_registration_statuses

  layout "full"

  def show
    scope =
      @session.patients.includes_statuses.includes(
        :registration_statuses,
        notes: :created_by
      )

    patients = @form.apply(scope)

    @pagy, @patients = pagy(patients)
  end

  private

  def set_registration_statuses
    @registration_statuses =
      if @session.today? && @session.requires_registration?
        Patient::RegistrationStatus.statuses.keys
      else
        []
      end
  end
end
