class ConsentsController < ApplicationController
  before_action :set_session
  before_action :set_patient_sessions, only: %i[index]

  def index
    methods = %i[consent_given? consent_refused? consent_conflicts? no_consent?]

    @tabs =
      @patient_sessions.group_by do |patient_session|
        methods.find { |m| patient_session.send(m) }
      end

    methods.each { |m| @tabs[m] ||= [] }
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
        .includes(patient: :consents)
        .order("patients.first_name", "patients.last_name")
  end
end
