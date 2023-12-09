class ConsentsController < ApplicationController
  before_action :set_session
  before_action :set_patient_sessions, only: %i[index]
  before_action :set_patient, only: %i[show]
  before_action :set_patient_session, only: %i[show]

  layout "two_thirds", except: :index

  def index
    methods = %i[consent_given? consent_refused? consent_conflicts? no_consent?]

    @tabs =
      @patient_sessions.group_by do |patient_session|
        methods.find { |m| patient_session.send(m) }
      end

    methods.each { |m| @tabs[m] ||= [] }
  end

  def show
  end

  private

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def set_patient
    @patient = Patient.find(params.fetch(:patient_id) { params.fetch(:id) })
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_patient_sessions
    @patient_sessions =
      @session
        .patient_sessions
        .strict_loading
        .includes(:campaign, :consents, :patient)
        .sort_by { |ps| ps.patient.full_name }
  end
end
