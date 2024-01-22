# == Schema Information
#
# Table name: sessions
#
#  id          :bigint           not null, primary key
#  date        :datetime
#  draft       :boolean          default(FALSE)
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
  audited

  belongs_to :campaign
  belongs_to :location, optional: true
  has_many :consent_forms
  has_many :patient_sessions
  has_many :patients, through: :patient_sessions

  scope :active, -> { where(draft: false) }

  def health_questions
    campaign.vaccines.first.health_questions
  end

  delegate :name, to: :location

  def type
    campaign.name
  end

  def title
    Rails.logger.warn "Deprecation warning: Session#title is deprecated. Use Session#name instead."
    name
  end

  def in_progress?
    date.to_date == Time.zone.today
  end
end
