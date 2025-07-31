# frozen_string_literal: true

class Programmes::PatientsController < Programmes::BaseController
  include PatientSearchFormConcern

  before_action :set_patient_search_form

  def index
    @year_groups =
      policy_scope(Location::ProgrammeYearGroup).where(
        programme: @programme
      ).pluck_year_groups

    # The select is needed because the association scope has a `distinct` and
    # therefore anything in the ORDER BY needs to appear in the SELECT.
    scope =
      patients.select(
        "patients.*",
        "LOWER(given_name)",
        "LOWER(family_name)"
      ).includes(:consent_statuses, :triage_statuses, :vaccination_statuses)

    @form.programme_types = [@programme.type]

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end
end
