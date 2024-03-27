class ConsentsController < ApplicationController
  before_action :set_session
  before_action :set_patient_sessions, only: %i[index]

  layout "two_thirds", except: :index

  def index
    methods = %i[consent_given? consent_refused? consent_conflicts? no_consent?]

    @unmatched_record_counts =
      SessionStats.new(patient_sessions: @patient_sessions, session: @session)[
        :unmatched_responses
      ]

    @tabs =
      @patient_sessions.group_by do |patient_session|
        methods.find { |m| patient_session.send(m) }
      end

    methods.each { |m| @tabs[m] ||= [] }

    session[:current_section] = "consents"
  end

  private

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def set_patient_sessions
    @patient_sessions =
      @session
        .patient_sessions
        .strict_loading
        .includes(:campaign, :consents, :patient, :triage, :vaccination_records)
        .sort_by { |ps| ps.patient.full_name }
  end
end
