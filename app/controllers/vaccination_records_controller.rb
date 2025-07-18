# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  include Pagy::Backend
  include VaccinationMailerConcern

  before_action :set_vaccination_record, except: :index
  before_action :set_return_to, only: %i[confirm_destroy destroy]

  def index
    @pagy, @vaccination_records = pagy(vaccination_records)

    render layout: "full"
  end

  def show
  end

  def update
    DraftVaccinationRecord.new(
      request_session: session,
      current_user:
    ).read_from!(@vaccination_record)

    redirect_to draft_vaccination_record_path("confirm")
  end

  def confirm_destroy
    authorize @vaccination_record, :destroy?
    render :destroy
  end

  def destroy
    authorize @vaccination_record

    @vaccination_record.discard!

    StatusUpdater.call(patient: @vaccination_record.patient)

    if @vaccination_record.confirmation_sent?
      send_vaccination_deletion(@vaccination_record)
    end

    StatusUpdater.call(patient: @vaccination_record.patient)

    redirect_to @return_to, flash: { success: "Vaccination record deleted" }
  end

  private

  def programme
    @programme ||=
      policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .includes(
          :batch,
          :immunisation_imports,
          :location,
          :performed_by_user,
          :programme,
          patient: [:gp_practice, :school, { parent_relationships: :parent }],
          session: %i[session_dates],
          vaccine: :programme
        )
        .where(programme:)
        .order(:performed_at)
  end

  def set_vaccination_record
    @vaccination_record = vaccination_records.find(params[:id])
    @patient = @vaccination_record.patient
    @session = @vaccination_record.session
  end

  def set_return_to
    @return_to = params[:return_to] || patient_path(@patient)
  end
end
