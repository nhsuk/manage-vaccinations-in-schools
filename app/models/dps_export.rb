# frozen_string_literal: true

require "csv"

class DPSExport
  def initialize(campaign: nil, campaigns: nil)
    if campaign.present? && campaigns.blank?
      @campaigns = [campaign]
    elsif campaigns.present? && campaign.blank?
      @campaigns = campaigns
    else
      raise "Must provide a campaign"
    end
  end

  def csv
    @csv ||=
      CSV.generate(headers: true, force_quotes: true) do |csv|
        csv << DPSExportRow::FIELDS.map(&:upcase)

        unexported_vaccination_records.each { csv << DPSExportRow.new(_1).to_a }
      end
  end

  def export!
    csv.tap do
      unexported_vaccination_records.update_all(
        exported_to_dps_at: Time.zone.now
      )
    end
  end

  def filename
    raise "More than one campaign provided" if campaigns.count > 1

    date = Time.zone.today.strftime("%Y-%m-%d")
    campaign_name = campaigns.first.name.parameterize(preserve_case: true)
    "Vaccinations-#{campaign_name}-#{date}.csv"
  end

  def reset!
    exported_vaccination_records.update_all(exported_to_dps_at: nil)
  end

  private

  attr_reader :campaigns

  def vaccination_records
    @vaccination_records ||=
      VaccinationRecord
        .includes(:batch, :location, :patient, :session, :team, :vaccine)
        .where(sessions: { campaign: campaigns })
        .recorded
        .administered
        .order(:recorded_at)
        .strict_loading
  end

  def unexported_vaccination_records
    @unexported_vaccination_records ||=
      vaccination_records.where(exported_to_dps_at: nil)
  end

  def exported_vaccination_records
    @exported_vaccination_records ||=
      vaccination_records.where.not(exported_to_dps_at: nil)
  end
end
