# frozen_string_literal: true

class Programmes::PatientsController < Programmes::BaseController
  include PatientSearchFormConcern

  before_action :set_patient_search_form

  def index
    @year_groups = current_team.programme_year_groups[@programme]

    scope =
      patients.includes(
        :consent_statuses,
        :triage_statuses,
        :vaccination_statuses,
        school: :location_programme_year_groups
      )

    @form.academic_year = @academic_year
    @form.programme_types = [@programme.type]

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end

  def import
    draft_import = DraftImport.new(request_session: session, current_user:)

    draft_import.clear_attributes
    draft_import.update!(type: "cohort")

    steps = draft_import.wizard_steps
    steps.delete(:type)

    next_step =
      steps.present? ? I18n.t(steps.first, scope: :wicked) : Wicked::FINISH_STEP
    redirect_to draft_import_path(next_step)
  end
end
