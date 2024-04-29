class TriageController < ApplicationController
  include TriageMailerConcern
  include PatientTabsConcern

  before_action :set_session, only: %i[index create update]
  before_action :set_patient, only: %i[create update]
  before_action :set_patient_session, only: %i[create update]
  before_action :set_consent, only: %i[create update]
  before_action :set_section_and_tab, only: %i[create update]

  after_action :verify_policy_scoped, only: %i[index update]

  layout "two_thirds", except: %i[index]

  def index
    all_patient_sessions =
      @session
        .patient_sessions
        .strict_loading
        .includes(:campaign, :patient, :triage, :vaccination_records)
        .preload(:consents)
        .order("patients.first_name", "patients.last_name")

    @current_tab = TAB_PATHS[:triage][params[:tab]]
    tab_patient_sessions =
      group_patient_sessions_by_state(all_patient_sessions, section: :triage)
    @tab_counts = count_patient_sessions(tab_patient_sessions)
    @patient_sessions = tab_patient_sessions[@current_tab] || []
    session[:current_section] = "triage"
  end

  def create
    @triage = @patient_session.triage.new
    @triage.assign_attributes triage_params.merge(user: current_user)
    if @triage.save(context: :consent)
      @patient_session.do_triage!
      send_triage_mail(@patient_session, @consent)
      success_flash_after_patient_update(
        patient: @patient,
        view_record_link: session_patient_path(@session, id: @patient.id)
      )
      redirect_to redirect_path
    else
      render "patients/show", status: :unprocessable_entity
    end
  end

  def update
    @triage = @patient_session.triage.last
    @triage.assign_attributes triage_params
    if @triage.save(context: :consent)
      @patient_session.do_triage!
      send_triage_mail(@patient_session, @consent)
      success_flash_after_patient_update(
        patient: @patient,
        view_record_link: session_patient_path(@session, id: @patient.id)
      )
      redirect_to redirect_path
    else
      render "patients/show", status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def set_patient
    @patient = @session.patients.find_by(id: params[:patient_id])
  end

  def set_consent
    # HACK: Triage needs to be updated to work with multiple consents.
    @consent = @patient_session.consents.first
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end

  def triage_params
    params.require(:triage).permit(:status, :notes)
  end

  def redirect_path
    if session[:current_section] == "vaccinations"
      session_vaccinations_path(@session)
    elsif session[:current_section] == "consents"
      session_consents_tab_path(@session, tab: params[:tab])
    else # if current_section is triage or anything else
      session_triage_path(@session)
    end
  end
end
