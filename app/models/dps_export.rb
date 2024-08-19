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
  before_create :set_filename
  before_create :set_vaccination_records

  belongs_to :campaign
  has_and_belongs_to_many :vaccination_records

  def csv
    @csv ||=
      CSV.generate(headers: true, force_quotes: true, col_sep: "|") do |csv|
        csv << DPSExportRow::FIELDS.map(&:upcase)

        vaccination_records
          .includes(:batch, :location, :patient, :session, :team, :vaccine)
          .order(:recorded_at)
          .strict_loading
          .find_each { csv << DPSExportRow.new(_1).to_a }
      end
  end

  private

  def set_filename
    date = Time.zone.today.strftime("%Y-%m-%d")
    campaign_name = campaign.name.parameterize(preserve_case: true)
    self.filename = "Vaccinations-#{campaign_name}-#{date}.csv"
  end

  def set_vaccination_records
    self.vaccination_records =
      campaign.vaccination_records.recorded.administered.unexported
  end
end
