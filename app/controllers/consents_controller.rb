# frozen_string_literal: true

class ConsentsController < ApplicationController
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_patient, only: %i[create send_request]
  before_action :set_patient_session, only: %i[create send_request]
  before_action :set_consent, except: %i[index create send_request]
  before_action :ensure_can_withdraw, only: %i[edit_withdraw update_withdraw]
  before_action :ensure_can_invalidate,
                only: %i[edit_invalidate update_invalidate]

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

  def create
    @consent = Consent.create!(create_params)

    redirect_to session_patient_consent_edit_path(
                  @session,
                  @patient,
                  @consent,
                  id: Wicked::FIRST_STEP,
                  section: params[:section],
                  tab: params[:tab]
                )
  end

  def send_request
    return unless @patient_session.no_consent?

    @session.programmes.each do |programme|
      ConsentNotification.create_and_send!(
        patient: @patient,
        programme:,
        session: @session,
        type: :request,
        current_user:
      )
    end

    redirect_to session_patient_path(
                  @session,
                  @patient,
                  section: params[:section],
                  tab: params[:tab]
                ),
                flash: {
                  success: "Consent request sent."
                }
  end

  def show
  end

  def edit_withdraw
    render :withdraw
  end

  def update_withdraw
    @consent.assign_attributes(withdraw_params)

    if @consent.save
      redirect_to session_patient_consent_path
    else
      render :withdraw, status: :unprocessable_entity
    end
  end

  def edit_invalidate
    render :invalidate
  end

  def update_invalidate
    @consent.assign_attributes(invalidate_params)

    if @consent.save
      redirect_to session_patient_consent_path
    else
      render :invalidate, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:location, :organisation).find_by!(
        slug: params[:session_slug]
      )
  end

  def set_patient
    @patient = @session.patients.find(params[:patient_id])
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by!(session: @session)
  end

  def set_consent
    @consent =
      Consent.where(programme: @session.programmes).recorded.find(params[:id])
  end

  def ensure_can_withdraw
    redirect_to action: :show unless @consent.can_withdraw?
  end

  def ensure_can_invalidate
    redirect_to action: :show unless @consent.can_invalidate?
  end

  def create_params
    {
      patient: @patient,
      programme: @session.programmes.first, # TODO: handle multiple programmes
      organisation: @session.organisation,
      recorded_by: current_user,
      route: @patient_session.gillick_competent? ? :self_consent : nil
    }
  end

  def withdraw_params
    params
      .require(:consent)
      .permit(:reason_for_refusal, :notes)
      .merge(response: "refused", withdrawn_at: Time.current)
  end

  def invalidate_params
    params.require(:consent).permit(:notes).merge(invalidated_at: Time.current)
  end
end
