# frozen_string_literal: true

class ReportsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: %i[index]

  def index
  end

  def show
    vaccinations =
      policy_scope(VaccinationRecord)
        .administered
        .recorded
        .includes(:session, :patient, :campaign, batch: :vaccine)
        .order("vaccination_records.recorded_at")

    csv = NivsReport.new(vaccinations).to_csv
    send_data(csv, filename: "NIVS-HPV-report-MAVIS.csv")
  end
end
