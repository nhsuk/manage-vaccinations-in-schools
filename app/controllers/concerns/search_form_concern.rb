# frozen_string_literal: true

module SearchFormConcern
  extend ActiveSupport::Concern

  def set_search_form
    @form =
      SearchForm.new(
        session: @session,
        request_path: request.path,
        request_session: session,
        **search_form_params
      )
  end

  private

  def search_form_params
    params.fetch(:search_form, {}).permit(
      :clear_filters,
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
