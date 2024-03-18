class Vaccinations::BatchesController < ApplicationController
  include TodaysBatchConcern

  before_action :set_session, only: %i[edit update]
  before_action :set_patient, only: %i[edit update]
  before_action :set_patient_session, only: %i[edit update]
  before_action :set_draft_vaccination_record, only: %i[edit update]
  before_action :set_batches, only: %i[edit update]

  def update
    @draft_vaccination_record.assign_attributes(vaccination_record_batch_params)
    if @draft_vaccination_record.save(context: :edit_batch)
      update_default_batch_for_today
      redirect_to confirm_session_patient_vaccinations_path(@session, @patient)
    else
      render action: :edit
    end
  end

  def edit
  end

  private

  def set_batches
    @batches = @session.campaign.batches
  end

  def set_draft_vaccination_record
    @draft_vaccination_record =
      @patient.draft_vaccination_records_for_session(@session).find_by(
        recorded_at: nil
      )

    raise UnprocessableEntity unless @draft_vaccination_record
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

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def update_default_batch_for_today
    if params.dig(:vaccination_record, :todays_batch).present? &&
         vaccination_record_batch_params[:batch_id].in?(
           params[:vaccination_record][:todays_batch]
         )
      self.todays_batch_id = vaccination_record_batch_params[:batch_id]
    end
  end

  def vaccination_record_batch_params
    params.fetch(:vaccination_record, {}).permit(:batch_id)
  end
end
