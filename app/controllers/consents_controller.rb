class ConsentsController < ApplicationController
  include PatientTabsConcern

  before_action :set_session

  layout "two_thirds", except: :index

  def index
    all_patient_sessions =
      @session
        .patient_sessions
        .strict_loading
        .includes(:campaign, :consents, :patient, :triage, :vaccination_records)
        .sort_by { |ps| ps.patient.full_name }

    @unmatched_record_counts =
      SessionStats.new(
        patient_sessions: all_patient_sessions,
        session: @session
      )[
        :unmatched_responses
      ]

    tab_patient_sessions =
      group_patient_sessions_by_conditions(
        all_patient_sessions,
        section: :consents
      )

    @current_tab = TAB_PATHS[:consents][params[:tab]]
    @tab_counts = count_patient_sessions(tab_patient_sessions)
    @patient_sessions = tab_patient_sessions[@current_tab] || []

    session[:current_section] = "consents"
  end

  private

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end
end
