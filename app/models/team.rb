# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                 :bigint           not null, primary key
#  email              :string
#  name               :text             not null
#  ods_code           :string           not null
#  phone              :string
#  privacy_policy_url :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  reply_to_id        :uuid
#
# Indexes
#
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#
class Team < ApplicationRecord
  has_many :cohort_imports
  has_many :cohorts
  has_many :programmes

  has_and_belongs_to_many :users

  validates :email, presence: true, notify_safe_email: true
  validates :name, presence: true, uniqueness: true
  validates :ods_code, presence: true, uniqueness: true
  validates :phone, presence: true, phone: true

  def programme
    # TODO: Update the app to properly support multiple programmes per team
    programmes.first
  end
end
