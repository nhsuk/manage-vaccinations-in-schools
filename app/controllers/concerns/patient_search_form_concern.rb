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
      :eligible_children,
      :missing_nhs_number,
      :patient_specific_direction_status,
      :q,
      :register_status,
      :still_to_vaccinate,
      :triage_status,
      :vaccination_status,
      :vaccine_criteria,
      consent_statuses: [],
      programme_types: [],
      year_groups: []
    )
  end
end
