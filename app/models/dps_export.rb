# frozen_string_literal: true

# == Schema Information
#
# Table name: dps_exports
#
#  id          :bigint           not null, primary key
#  filename    :string           not null
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
  after_create :set_filename
  after_create :populate

  belongs_to :campaign
  has_and_belongs_to_many :vaccination_records

  def csv
    @csv ||=
      CSV.generate(headers: true, force_quotes: true) do |csv|
        csv << DPSExportRow::FIELDS.map(&:upcase)

        vaccination_records.each { csv << DPSExportRow.new(_1).to_a }
      end
  end

  private

  def set_filename
    date = created_at.strftime("%Y-%m-%d")
    campaign_name = campaign.name.parameterize(preserve_case: true)
    update!(filename: "Vaccinations-#{campaign_name}-#{date}.csv")
  end

  def populate
    vaccination_records << VaccinationRecord
      .includes(:batch, :location, :patient, :session, :team, :vaccine)
      .where(sessions: { campaign: })
      .recorded
      .administered
      .unexported
      .order(:recorded_at)
      .strict_loading
  end
end
