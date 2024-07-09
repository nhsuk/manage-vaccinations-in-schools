# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_campaign

  def index
  end

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

  private

  def set_campaign
    @campaign = policy_scope(Campaign).find(params[:campaign_id])
  end
end
