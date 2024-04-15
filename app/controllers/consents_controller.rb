class ConsentsController < ApplicationController
  before_action :set_session

  layout "two_thirds", except: :index

  def index
    tab_conditions = {
      consent_given: %i[consent_given?],
      consent_refused: %i[consent_refused?],
      conflicting_consent: %i[consent_conflicts?],
      no_consent: %i[no_consent?]
    }

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

    @current_tab = TAB_PATHS[:consent][params[:tab]]

    tab_patient_sessions =
      all_patient_sessions.group_by do |patient_session|
        tab_conditions
          .find { |_, conditions| conditions.any? { patient_session.send(_1) } }
          &.first
      end
    @tab_counts = tab_patient_sessions.transform_values(&:count)
    tab_conditions.each_key { |tab| @tab_counts[tab] ||= 0 }

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
