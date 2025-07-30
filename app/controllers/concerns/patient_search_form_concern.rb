# frozen_string_literal: true

module PatientSearchFormConcern
  extend ActiveSupport::Concern

  def set_patient_search_form
    @form =
      PatientSearchForm.new(
        request_path: request.path,
        request_session: session,
        session: @session,
        **patient_search_form_params
      )
  end

  private

  def patient_search_form_params
    params.permit(
      :_clear,
      :date_of_birth_day,
      :date_of_birth_month,
      :date_of_birth_year,
      :missing_nhs_number,
      :programme_status,
      :q,
      :register_status,
      :session_status,
      :triage_status,
      :vaccine_method,
      consent_statuses: [],
      programme_types: [],
      year_groups: []
    )
  end
end
