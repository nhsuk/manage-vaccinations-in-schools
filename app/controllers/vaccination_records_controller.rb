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

  def dps_export
    date = Time.zone.today.strftime("%Y-%m-%d")
    campaign_name = campaign.name.parameterize(preserve_case: true)
    filename = "DPS-export-#{campaign_name}-#{date}.csv"
    csv = DPSExport.new(unexported_administered_vaccination_records).export_csv
    send_data(csv, filename:)
  end

  private

  def campaign
    @campaign ||= policy_scope(Campaign).find(params[:campaign_id])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .includes(
          :batch,
          :campaign,
          :location,
          :user,
          :vaccine,
          campaign: :team,
          patient: :location,
          session: :location
        )
        .recorded
        .where(campaign:)
        .order(:recorded_at)
        .strict_loading
  end

  def administered_vaccination_records
    @administered_vaccination_records ||= vaccination_records.administered
  end

  def unexported_administered_vaccination_records
    @unexported_administered_vaccination_records ||=
      administered_vaccination_records.where(exported_to_dps_at: nil)
  end
end
