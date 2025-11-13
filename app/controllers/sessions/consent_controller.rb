# frozen_string_literal: true

class Sessions::ConsentController < Sessions::BaseController
  include PatientSearchFormConcern

  before_action :set_statuses
  before_action :set_patient_search_form

  layout "full"

  def show
    statuses_except_not_required =
      Patient::ConsentStatus.statuses.keys - %w[not_required]

    scope =
      @session
        .patients
        .includes(:consent_statuses, :triage_statuses, { notes: :created_by })
        .has_consent_status(
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

    @statuses = %w[no_response]

    unless programmes.all?(&:has_multiple_vaccine_methods?)
      @statuses << "given_injection"
    end

    if programmes.any?(&:has_multiple_vaccine_methods?)
      @statuses << "given_nasal"
    end

    if programmes.any?(&:vaccine_may_contain_gelatine?)
      @statuses << "given_injection_without_gelatine"
    end

    @statuses += %w[refused conflicts]
  end
end
