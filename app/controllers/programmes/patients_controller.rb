# frozen_string_literal: true

class Programmes::PatientsController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_programme
  before_action :set_search_form

  layout "full"

  def index
    scope =
      policy_scope(Patient).includes(:vaccination_statuses).in_programmes(
        [@programme]
      )

    @form.programme_types = [@programme.type]

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
