# frozen_string_literal: true

class ReportsController < ApplicationController
  def dps_export_reset
    @campaign = policy_scope(Campaign).find(params[:campaign_id])

    vaccination_records.update_all(exported_to_dps_at: nil)

    flash[:success] = {
      heading: "Vaccination records have been reset for the DPS export"
    }

    redirect_to campaign_immunisation_imports_path(@campaign)
  end

  private

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .administered
        .recorded
        .where(campaign: @campaign)
        .includes(:session, :patient, :campaign, batch: :vaccine)
        .order("vaccination_records.recorded_at")
  end
end
