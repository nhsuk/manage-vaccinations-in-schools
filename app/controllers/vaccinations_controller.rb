# frozen_string_literal: true

class VaccinationsController < ApplicationController
  include TodaysBatchConcern
  include VaccinationMailerConcern
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_patient, except: %i[index batch update_batch]
  before_action :set_patient_session, only: %i[create]

  before_action :set_batches, only: %i[index create batch update_batch]
  before_action :set_todays_batch, only: %i[index create batch]
  before_action :set_section_and_tab, only: %i[create]

  after_action :verify_authorized

  def index
    authorize VaccinationRecord

    all_patient_sessions =
      @session
        .patient_sessions
        .preload_for_state
        .eager_load(patient: :cohort)
        .order_by_name
        .strict_loading

    grouped_patient_sessions =
      group_patient_sessions_by_state(
        all_patient_sessions,
        section: :vaccinations
      )

    @current_tab = TAB_PATHS[:vaccinations][params[:tab]]
    @tab_counts = count_patient_sessions(grouped_patient_sessions)
    @patient_sessions = grouped_patient_sessions.fetch(@current_tab, [])

    sort_and_filter_patients!(@patient_sessions)

    session[:current_section] = "vaccinations"

    respond_to do |format|
      format.html { render layout: "full" }
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end
  end

  def create
    authorize VaccinationRecord

    @draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:).tap(
        &:reset!
      )

    @draft_vaccination_record.assign_attributes(create_params)

    if @draft_vaccination_record.save
      steps = @draft_vaccination_record.wizard_steps

      steps.delete(:outcome) if @draft_vaccination_record.administered?
      steps.delete(:date_and_time)
      if @draft_vaccination_record.delivery_method.present? &&
           @draft_vaccination_record.delivery_site.present?
        steps.delete(:delivery)
      end
      steps.delete(:vaccine) if @draft_vaccination_record.vaccine.present?
      steps.delete(:batch) if @draft_vaccination_record.batch.present?

      redirect_to draft_vaccination_record_path(
                    I18n.t(steps.first, scope: :wicked)
                  )
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  def batch
    authorize Batch, :index?
  end

  def update_batch
    @todays_batch = @batches.find_by(params.fetch(:batch).permit(:id))

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
      .require(:vaccination_record)
      .permit(
        :administered,
        :delivery_method,
        :delivery_site,
        :dose_sequence,
        :programme_id,
        :vaccine_id
      )
      .merge(patient_session: @patient_session, wizard_step: :date_and_time)
  end

  def create_params
    if vaccination_record_params[:administered] == "true"
      create_params =
        if delivery_site_param_other?
          vaccination_record_params.except(:delivery_site, :delivery_method)
        else
          vaccination_record_params
        end

      create_params.except(:administered).merge(
        administered_at: Time.current,
        batch_id: @todays_batch&.id
      )
    else
      vaccination_record_params.except(:administered).merge(
        administered_at: nil
      )
    end
  end

  def delivery_site_param_other?
    vaccination_record_params[:delivery_site] == "other"
  end

  def set_session
    @session =
      policy_scope(Session).includes(:location).find_by!(
        slug: params[:session_slug] || params[:slug]
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).find(
        params.fetch(:patient_id) { params.fetch(:id) }
      )
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_batches
    @batches =
      policy_scope(Batch)
        .where(vaccine: @session.vaccines)
        .not_expired
        .order_by_name_and_expiration
  end

  def set_todays_batch
    @todays_batch = @batches.find_by(id: todays_batch_id)
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end
end
