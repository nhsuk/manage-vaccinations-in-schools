# frozen_string_literal: true

class Sessions::TriageController < Sessions::BaseController
  include PatientSearchFormConcern

  before_action :set_statuses
  before_action :set_patient_search_form

  layout "full"

  def show
    statuses_except_not_required =
      Patient::TriageStatus.statuses.keys - %w[not_required]

    scope =
      @session
        .patients
        .includes(:triage_statuses, notes: :created_by)
        .has_triage_status(
          statuses_except_not_required,
          programme: @form.programmes,
          academic_year: @session.academic_year
        )

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end

  private

  def set_statuses
    programmes = @session.programmes

    @statuses = %w[required]

    unless programmes.all?(&:has_multiple_vaccine_methods?)
      @statuses << "safe_to_vaccinate_injection"
    end

    if programmes.any?(&:has_multiple_vaccine_methods?)
      @statuses << "safe_to_vaccinate_nasal"
    end

    if programmes.any?(&:vaccine_may_contain_gelatine?)
      @statuses << "safe_to_vaccinate_injection_without_gelatine"
    end

    @statuses += %w[do_not_vaccinate delay_vaccination invite_to_clinic]
  end
end
