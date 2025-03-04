# frozen_string_literal: true

module SearchFormConcern
  extend ActiveSupport::Concern

  def set_search_form
    @form =
      SearchForm.new(
        params.fetch(:search_form, {}).permit(
          :"date_of_birth(1i)",
          :"date_of_birth(2i)",
          :"date_of_birth(3i)",
          :consent_status,
          :missing_nhs_number,
          :q,
          :triage_status,
          year_groups: []
        )
      )
  end
end
