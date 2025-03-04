# frozen_string_literal: true

module SearchFormConcern
  extend ActiveSupport::Concern

  def set_search_form
    @form =
      SearchForm.new(
        params.fetch(:search_form, {}).permit(
          %w[
            q
            date_of_birth(3i)
            date_of_birth(2i)
            date_of_birth(1i)
            missing_nhs_number
          ]
        )
      )
  end
end
