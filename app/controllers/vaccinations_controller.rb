# frozen_string_literal: true

class VaccinationsController < ApplicationController
  include TodaysBatchConcern
  include VaccinationMailerConcern
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_patient, except: %i[index batch update_batch]
  before_action :set_patient_session, only: %i[edit_reason create update]
  before_action :set_draft_vaccination_record,
                only: %i[edit_reason create update]

  before_action :set_todays_batch, only: %i[index batch create]
  before_action :set_batches, only: %i[batch update_batch]
  before_action :set_section_and_tab, only: %i[create update]

  layout "two_thirds", except: :index

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

    grouped_patient_sessions =
      group_patient_sessions_by_state(
        all_patient_sessions,
        section: :vaccinations
      )

    @current_tab = TAB_PATHS[:vaccinations][params[:tab]]
    @tab_counts = count_patient_sessions(grouped_patient_sessions)
    @patient_sessions = grouped_patient_sessions.fetch(@current_tab, [])

    respond_to do |format|
      format.html
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end

    sort_and_filter_patients!(@patient_sessions)

    session[:current_section] = "vaccinations"
  end

  def edit_reason
  end

  def create
    if @draft_vaccination_record.update create_params.merge(user: current_user)
      if @draft_vaccination_record.administered?
        if @draft_vaccination_record.delivery_site_other
          redirect_to edit_session_patient_vaccinations_delivery_site_path(
                        @session,
                        patient_id: @patient.id
                      )
        elsif @draft_vaccination_record.batch_id.present?
          redirect_to session_patient_vaccinations_edit_path(
                        @session,
                        patient_id: @patient.id,
                        id: @draft_vaccination_record.form_steps.first
                      )
        else
          redirect_to edit_session_patient_vaccinations_batch_path(
                        @session,
                        patient_id: @patient.id
                      )
        end
      else
        redirect_to edit_reason_session_patient_vaccinations_path(
                      @session,
                      patient_id: @patient.id
                    )
      end
    else
      render "patients/show", status: :unprocessable_entity
    end
  end

  def update
    @draft_vaccination_record.assign_attributes(vaccination_record_params)
    if @draft_vaccination_record.save(context: :edit_reason)
      redirect_to session_patient_vaccinations_edit_path(
                    @session,
                    patient_id: @patient.id,
                    id: @draft_vaccination_record.form_steps.first
                  )
    else
      render :edit_reason
    end
  end

  def batch
  end

  def update_batch
    @todays_batch =
      policy_scope(Batch).find_by(params.fetch(:batch).permit(:id))

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
    params.fetch(:vaccination_record, {}).permit(
      :administered,
      :delivery_site,
      :delivery_method,
      :reason,
      :batch_id
    )
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

  def vaccination_record_administered_params
    params.fetch(:vaccination_record, {}).permit(:administered, :delivery_site)
  end

  def vaccination_record_reason_params
    params.fetch(:vaccination_record, {}).permit(:reason)
  end

  def consent_params
    params.fetch(:consent, {}).permit(:route)
  end

  def delivery_site_param_other?
    vaccination_record_params[:delivery_site] == "other"
  end

  def set_session
    @session =
      policy_scope(Session).find(
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
    @batches = @session.campaign.batches.order(expiry: :asc, name: :asc)
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end
end
