# frozen_string_literal: true

module SchoolSearchFormConcern
  extend ActiveSupport::Concern

  include Pagy::Backend

  def set_school_search_form
    @form =
      SchoolSearchForm.new(
        request_path: request.path,
        request_session: session,
        **school_search_form_params
      )
  end

  private

  def school_search_form_params
    params.permit(:_clear, :phase, :q)
  end
end
