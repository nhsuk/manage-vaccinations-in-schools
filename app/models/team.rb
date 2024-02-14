# == Schema Information
#
# Table name: teams
#
#  id                 :bigint           not null, primary key
#  email              :string
#  name               :text             not null
#  ods_code           :string
#  privacy_policy_url :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  reply_to_id        :string
#
# Indexes
#
#  index_teams_on_name  (name) UNIQUE
#
class Team < ApplicationRecord
  has_many :campaigns
  has_many :locations
  has_and_belongs_to_many :users

  validates :name, presence: true
  validates :name, uniqueness: true

  MAX_COHORT_SIZE = 100

  def campaign
    # TODO: Update the app to properly support multiple campaigns per team
    campaigns.first
  end

  def cohort_size
    @cohort_size ||= locations.map(&:patients).map(&:size).reduce(&:+) || 0
  end

  def remaining_cohort_size
    MAX_COHORT_SIZE - cohort_size
  end
end
