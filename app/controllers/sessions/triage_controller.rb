# frozen_string_literal: true

class Sessions::TriageController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    @statuses = Patient::TriageStatus.statuses.keys - %w[not_required]

    scope =
      @session
        .patients
        .includes(:triage_statuses, notes: :created_by)
        .has_triage_status(
          @statuses,
          programme: @form.programmes,
          academic_year: @session.academic_year
        )

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end
end
