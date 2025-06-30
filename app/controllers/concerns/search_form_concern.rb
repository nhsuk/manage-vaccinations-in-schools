# frozen_string_literal: true

module SearchFormConcern
  extend ActiveSupport::Concern

  def set_search_form
    @form =
      SearchForm.new(
        **params.fetch(:search_form, {}).permit(
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
          year_groups: []
        ),
        session: session,
        request_path: request.path
      )
  end
end
