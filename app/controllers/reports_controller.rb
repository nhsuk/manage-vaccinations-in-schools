# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_campaign

  def dps_export
    date = Time.zone.today.strftime("%Y-%m-%d")
    filename =
      "DPS-export-#{@campaign.name.parameterize(preserve_case: true)}-#{date}.csv"

    csv = DPSExport.new(vaccination_records_for_dps_export).export_csv
    send_data(csv, filename:)
  end

  def dps_export_reset
    vaccination_records.update_all(exported_to_dps_at: nil)

    flash[:success] = {
      heading: "Vaccination records have been reset for the DPS export"
    }

    redirect_to campaign_immunisation_imports_path(@campaign)
  end

  private

  def set_campaign
    @campaign = policy_scope(Campaign).find(params[:campaign_id])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .administered
        .recorded
        .where(campaign: @campaign)
        .includes(:session, :patient, :campaign, batch: :vaccine)
        .order("vaccination_records.recorded_at")
  end

  def vaccination_records_for_dps_export
    @vaccination_records_for_dps_export ||=
      vaccination_records.where(exported_to_dps_at: nil)
  end
end
