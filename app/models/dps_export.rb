# frozen_string_literal: true

# == Schema Information
#
# Table name: dps_exports
#
#  id          :bigint           not null, primary key
#  filename    :string
#  sent_at     :datetime
#  status      :string           default("pending"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  message_id  :string
#
# Indexes
#
#  index_dps_exports_on_campaign_id  (campaign_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#
require "csv"

class DPSExport < ApplicationRecord
  belongs_to :campaign

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
    date = Time.zone.today.strftime("%Y-%m-%d")
    campaign_name = campaign.name.parameterize(preserve_case: true)
    "Vaccinations-#{campaign_name}-#{date}.csv"
  end

  def reset!
    exported_vaccination_records.update_all(exported_to_dps_at: nil)
  end

  private

  def vaccination_records
    @vaccination_records ||=
      VaccinationRecord
        .includes(:batch, :location, :patient, :session, :team, :vaccine)
        .where(sessions: { campaign: })
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
