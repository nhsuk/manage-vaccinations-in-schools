# frozen_string_literal: true

require "pagy/extras/array"

class ConsentFormsController < ApplicationController
  include Pagy::Backend
  include PatientSortingConcern

  before_action :set_consent_form, except: :index
  before_action :set_patient, only: %i[edit_match update_match]

  layout "full"

  def index
    @pagy, @consent_forms = pagy(consent_form_scope.order(:recorded_at))
  end

  def show
    patients = policy_scope(Patient).to_a
    sort_and_filter_patients!(patients)
    @pagy, @patients = pagy_array(patients)
  end

  def edit_match
    render :match
  end

  def update_match
    @consent_form.match_with_patient!(@patient)

    session = @patient.upcoming_sessions.first || @consent_form.original_session

    flash[:success] = {
      heading: "Consent matched for",
      heading_link_text: @patient.full_name,
      heading_link_href:
        session_patient_path(
          session,
          id: @patient.id,
          section: "triage",
          tab: "given"
        )
    }

    redirect_to action: :index
  end

  private

  def consent_form_scope
    policy_scope(ConsentForm).unmatched.recorded
  end

  def set_consent_form
    @consent_form = consent_form_scope.find(params[:id])
  end

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end
end
