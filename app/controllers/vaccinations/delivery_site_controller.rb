class Vaccinations::DeliverySiteController < ApplicationController
  before_action :set_session, only: %i[edit update]
  before_action :set_patient, only: %i[edit update]
  before_action :set_patient_session, only: %i[edit update]
  before_action :set_draft_vaccination_record, only: %i[edit update]

  def update
    @draft_vaccination_record.assign_attributes(
      vaccination_record_delivery_params
    )
    if @draft_vaccination_record.save(context: :edit_delivery)
      if @draft_vaccination_record.batch_id.present?
        redirect_to confirm_session_patient_vaccinations_path(
                      @session,
                      @patient
                    )
      else
        redirect_to edit_session_patient_vaccinations_batch_path(
                      @session,
                      @patient
                    )
      end
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

  def vaccination_record_delivery_params
    params
      .fetch(:vaccination_record, {})
      .permit(:delivery_site, :delivery_method)
      .merge(administered: true)
  end
end
