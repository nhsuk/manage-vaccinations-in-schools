# frozen_string_literal: true

class TriagesController < ApplicationController
  include TriageMailerConcern
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_programme
  before_action :set_patient, only: %i[create new]
  before_action :set_patient_session, only: %i[create new]
  before_action :set_triage, only: %i[create new]
  before_action :set_section_and_tab, only: %i[create new]

  after_action :verify_authorized

  def index
    all_patient_sessions =
      @session
        .patient_sessions
        .preload_for_status
        .eager_load(:patient)
        .merge(Patient.in_programme(@programme))
        .order_by_name

    @current_tab = TAB_PATHS[:triage][params[:tab]]
    tab_patient_sessions =
      group_patient_sessions_by_state(
        all_patient_sessions,
        @programme,
        section: :triage
      )
    @tab_counts = count_patient_sessions(tab_patient_sessions)
    @patient_sessions = tab_patient_sessions[@current_tab] || []

    sort_and_filter_patients!(@patient_sessions, programme: @programme)

    session[:current_section] = "triage"

    authorize Triage

    render layout: "full"
  end

  def new
    authorize @triage
  end

  def create
    @triage.assign_attributes(triage_params.merge(performed_by: current_user))

    authorize @triage

    if @triage.save(context: :consent)
      @patient_session
        .reload
        .latest_consents(programme: @triage.programme)
        .each { send_triage_confirmation(@patient_session, it) }

      flash[:success] = {
        heading: "Triage outcome updated for",
        heading_link_text: @patient.full_name,
        heading_link_href:
          session_patient_programme_path(patient_id: @patient.id)
      }

      redirect_to redirect_path
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:location, :programmes).find_by!(
        slug: params[:session_slug] || params[:slug]
      )
  end

  def set_programme
    @programme =
      @session.programmes.find_by(type: params[:programme_type]) ||
        @session.programmes.first
  end

  def set_patient
    @patient =
      @session
        .patients
        .includes(:consents, :school, parent_relationships: :parent)
        .find_by(id: params[:patient_id])
  end

  def set_patient_session
    @patient_session =
      @patient.patient_sessions.preload_for_status.find_by!(session: @session)
  end

  def set_triage
    @triage =
      Triage.new(
        patient: @patient,
        programme: @programme,
        organisation: @session.organisation
      )
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end

  def triage_params
    params.expect(triage: %i[status notes])
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
