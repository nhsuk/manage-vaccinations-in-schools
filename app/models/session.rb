# == Schema Information
#
# Table name: sessions
#
#  id          :bigint           not null, primary key
#  date        :datetime
#  name        :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  location_id :bigint
#
# Indexes
#
#  index_sessions_on_campaign_id  (campaign_id)
#
class Session < ApplicationRecord
  belongs_to :campaign
  belongs_to :location, optional: true
  has_many :patient_sessions
  has_many :patients, through: :patient_sessions

  validates :name, presence: true
  validates :date, presence: true

  def type
    campaign.name
  end

  def title
    Rails.logger.warn "Deprecation warning: Session#title is deprecated. Use Session#name instead."
    name
  end
end
