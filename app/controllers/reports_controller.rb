# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_campaign

  def download
    vaccinations =
      policy_scope(VaccinationRecord)
        .administered
        .recorded
        .where(campaign: @campaign)
        .includes(:session, :patient, :campaign, batch: :vaccine)
        .order("vaccination_records.recorded_at")

    csv = NivsReport.new(vaccinations).to_csv
    filename =
      "NIVS-#{@campaign.name.parameterize(preserve_case: true)}-report-MAVIS.csv"

    send_data(csv, filename:)
  end

  def dps_export
    vaccinations =
      policy_scope(VaccinationRecord)
        .administered
        .recorded
        .where(campaign: @campaign)
        .where(exported_to_dps_at: nil)
        .includes(:session, :patient, :campaign, batch: :vaccine)
        .order("vaccination_records.recorded_at")

    date = Time.zone.today.strftime("%Y-%m-%d")
    filename =
      "DPS-export-#{@campaign.name.parameterize(preserve_case: true)}-#{date}.csv"

    csv = DPSExport.new(vaccinations).export_csv
    send_data(csv, filename:)
  end

  private

  def set_campaign
    @campaign = policy_scope(Campaign).find(params[:campaign_id])
  end
end
