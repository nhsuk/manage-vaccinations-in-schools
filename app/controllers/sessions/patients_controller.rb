# frozen_string_literal: true

class Sessions::PatientsController < Sessions::BaseController
  include PatientSearchFormConcern

  before_action :set_patient_search_form

  layout "full"

  def show
    @statuses = Patient::VaccinationStatus.statuses.keys - %w[not_eligible]

    scope = @session.patients.includes_statuses.includes(notes: :created_by)

    patients = @form.apply(scope)

    @pagy, @patients = pagy(patients)
  end
end
