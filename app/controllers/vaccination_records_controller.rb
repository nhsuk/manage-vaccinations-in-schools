# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  def index
    @vaccination_records = vaccination_records
  end

  def show
    @vaccination_record = vaccination_records.find(params[:id])
    @patient = @vaccination_record.patient
    @session = @vaccination_record.session
    @school = @patient.location
  end

  private

  def campaign
    @campaign ||= policy_scope(Campaign).find(params[:campaign_id])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord).includes(
        :vaccine,
        :batch,
        patient: :location,
        session: :location
      ).where(campaign:)
  end
end
