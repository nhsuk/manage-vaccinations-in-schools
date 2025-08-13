# frozen_string_literal: true

module PatientSearchFormConcern
  extend ActiveSupport::Concern

  include Pagy::Backend

  def set_patient_search_form
    @form =
      PatientSearchForm.new(
        current_user:,
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
      :aged_out_of_programmes,
      :archived,
      :date_of_birth_day,
      :date_of_birth_month,
      :date_of_birth_year,
      :missing_nhs_number,
      :programme_status,
      :q,
      :register_status,
      :triage_status,
      :vaccine_method,
      consent_statuses: [],
      programme_types: [],
      year_groups: []
    )
  end
end
