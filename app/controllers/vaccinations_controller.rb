# frozen_string_literal: true

class VaccinationsController < ApplicationController
  include TodaysBatchConcern
  include VaccinationMailerConcern
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_patient, except: %i[index batch update_batch]
  before_action :set_patient_session, only: %i[create]
  before_action :set_draft_vaccination_record, only: %i[create]

  before_action :set_todays_batch, only: %i[index batch create]
  before_action :set_batches, only: %i[batch update_batch]
  before_action :set_section_and_tab, only: %i[create]

  after_action :verify_authorized

  def index
    all_patient_sessions =
      @session
        .patient_sessions
        .strict_loading
        .includes(
          :programmes,
          :latest_gillick_assessment,
          :latest_vaccination_record,
          :vaccination_records,
          patient: :cohort
        )
        .preload(:consents, :triages)
        .order("patients.given_name", "patients.family_name")

    grouped_patient_sessions =
      group_patient_sessions_by_state(
        all_patient_sessions,
        section: :vaccinations
      )

    @current_tab = TAB_PATHS[:vaccinations][params[:tab]]
    @tab_counts = count_patient_sessions(grouped_patient_sessions)
    @patient_sessions = grouped_patient_sessions.fetch(@current_tab, [])

    respond_to do |format|
      format.html { render layout: "full" }
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end

    sort_and_filter_patients!(@patient_sessions)

    authorize VaccinationRecord

    session[:current_section] = "vaccinations"
  end

  def create
    authorize @draft_vaccination_record

    if @draft_vaccination_record.update(
         create_params.merge(performed_by: current_user)
       )
      session[:delivery_site_other] = "true" if delivery_site_param_other?

      @draft_vaccination_record.todays_batch = @todays_batch

      redirect_to session_patient_vaccinations_edit_path(
                    @session,
                    patient_id: @patient.id,
                    id: @draft_vaccination_record.wizard_steps.first
                  )
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  def batch
    authorize Batch, :index?
  end

  def update_batch
    @todays_batch =
      policy_scope(Batch).find_by(params.fetch(:batch).permit(:id))
    authorize @todays_batch, :update?

    if @todays_batch
      self.todays_batch_id = @todays_batch.id

      flash[:success] = {
        heading: "The default batch for this session has been updated"
      }
      redirect_to session_vaccinations_path(@session)
    else
      @todays_batch = Batch.new
      @todays_batch.errors.add(:id, "Select a default batch for this session")
      render :batch, status: :unprocessable_entity
    end
  end

  private

  def vaccination_record_params
    params
      .fetch(:vaccination_record, {})
      .permit(
        :administered,
        :delivery_site,
        :delivery_method,
        :reason,
        :batch_id
      )
      .merge(dose_sequence: 1)
  end

  def create_params
    if vaccination_record_params[:administered] == "true"
      create_params =
        if delivery_site_param_other?
          vaccination_record_params_with_delivery_other
        else
          vaccination_record_params
        end
      create_params.merge(batch_id: @todays_batch&.id)
    else
      vaccination_record_params
    end
  end

  def vaccination_record_params_with_delivery_other
    vaccination_record_params.except(:delivery_site, :delivery_method).merge(
      delivery_site_other: "true"
    )
  end

  def consent_params
    params.fetch(:consent, {}).permit(:route)
  end

  def delivery_site_param_other?
    vaccination_record_params[:delivery_site] == "other"
  end

  def set_session
    @session =
      policy_scope(Session).includes(:location).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).find(
        params.fetch(:patient_id) { params.fetch(:id) }
      )
  end

  def set_draft_vaccination_record
    @draft_vaccination_record = @patient_session.draft_vaccination_record
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_todays_batch
    @todays_batch = policy_scope(Batch).find_by(id: todays_batch_id)
  end

  def set_batches
    @batches =
      policy_scope(Batch).where(
        vaccine: @session.vaccines
      ).order_by_name_and_expiration
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end
end
