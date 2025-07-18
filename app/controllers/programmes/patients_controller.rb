# frozen_string_literal: true

class Programmes::PatientsController < Programmes::BaseController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_search_form

  def index
    scope =
      policy_scope(Patient).includes(:vaccination_statuses).in_programmes(
        [@programme]
      )

    @form.programme_types = [@programme.type]

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end
end
