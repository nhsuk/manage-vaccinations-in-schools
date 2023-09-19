# == Schema Information
#
# Table name: teams
#
#  id         :bigint           not null, primary key
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_teams_on_name  (name) UNIQUE
#
class Team < ApplicationRecord
  has_many :campaigns
  has_and_belongs_to_many :users

  validates :name, presence: true
  validates :name, uniqueness: true
end
