# frozen_string_literal: true

class ConsentsController < ApplicationController
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session

  def index
    all_patient_sessions =
      @session
        .patient_sessions
        .preload_for_state
        .preload(consents: :parent)
        .eager_load(patient: :cohort)
        .order_by_name
        .strict_loading

    tab_patient_sessions =
      group_patient_sessions_by_conditions(
        all_patient_sessions,
        section: :consents
      )

    @current_tab = TAB_PATHS[:consents][params[:tab]]
    @tab_counts = count_patient_sessions(tab_patient_sessions)
    @patient_sessions = tab_patient_sessions[@current_tab] || []

    sort_and_filter_patients!(@patient_sessions)

    session[:current_section] = "consents"

    render layout: "full"
  end

  def show
    @consent =
      Consent
        .where(programme: @session.programmes)
        .recorded
        .find(params[:consent_id])
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:location, :organisation).find_by!(
        slug: params[:session_slug] || params[:slug]
      )
  end
end
