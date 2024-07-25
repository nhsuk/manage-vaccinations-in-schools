# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  def index
    respond_to do |format|
      format.html { @vaccination_records = vaccination_records }

      format.csv do
        csv = NivsReport.new(vaccination_records.administered).to_csv
        filename =
          "NIVS-#{campaign.name.parameterize(preserve_case: true)}-report-MAVIS.csv"

        send_data(csv, filename:)
      end
    end
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
      policy_scope(VaccinationRecord)
        .includes(
          :campaign,
          :vaccine,
          :batch,
          patient: :location,
          session: :location
        )
        .where(campaign:)
        .recorded
        .order(:"vaccination_records.recorded_at")
  end
end
