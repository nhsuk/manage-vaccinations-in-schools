# frozen_string_literal: true

class Programmes::PatientsController < Programmes::BaseController
  include Pagy::Backend
  include PatientSearchFormConcern

  before_action :set_patient_search_form

  def index
    @year_groups =
      policy_scope(Location::ProgrammeYearGroup).where(
        programme: @programme
      ).pluck_year_groups

    scope =
      policy_scope(Patient).includes(
        :vaccination_statuses
      ).appear_in_programmes([@programme], academic_year: @academic_year)

    @form.programme_types = [@programme.type]

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end
end
