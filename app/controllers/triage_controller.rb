class TriageController < ApplicationController
  include TriageMailerConcern
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session, only: %i[index create new]
  before_action :set_patient, only: %i[create new]
  before_action :set_patient_session, only: %i[create new]
  before_action :set_section_and_tab, only: %i[create new]

  after_action :verify_policy_scoped, only: %i[index create new]

  layout "two_thirds", except: %i[index]

  def index
    all_patient_sessions =
      @session
        .patient_sessions
        .strict_loading
        .includes(
          :campaign,
          :gillick_assessment,
          :patient,
          :triage,
          :vaccination_records
        )
        .preload(:consents)
        .order("patients.first_name", "patients.last_name")

    @current_tab = TAB_PATHS[:triage][params[:tab]]
    tab_patient_sessions =
      group_patient_sessions_by_state(all_patient_sessions, section: :triage)
    @tab_counts = count_patient_sessions(tab_patient_sessions)
    @patient_sessions = tab_patient_sessions[@current_tab] || []

    sort_and_filter_patients!(@patient_sessions)

    session[:current_section] = "triage"
  end

  def new
    @triage = @patient_session.triage.new
  end

  def create
    @triage = @patient_session.triage.new
    process_triage
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

  def process_triage
    @triage.assign_attributes triage_params.merge(user: current_user)
    if @triage.save(context: :consent)
      @patient_session.do_triage!
      @patient.consents.each { send_triage_mail(@patient_session, _1) }
      flash[:success] = {
        heading: "Triage outcome updated for",
        heading_link_text: @patient.full_name,
        heading_link_href: session_patient_path(@session, id: @patient.id)
      }
      redirect_to redirect_path
    else
      render "patients/show", status: :unprocessable_entity
    end
  end
end
