# frozen_string_literal: true

# == Schema Information
#
# Table name: subteams
#
#  id                 :bigint           not null, primary key
#  email              :string           not null
#  name               :string           not null
#  phone              :string           not null
#  phone_instructions :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  reply_to_id        :uuid
#  team_id            :bigint           not null
#
# Indexes
#
#  index_subteams_on_team_id_and_name  (team_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Subteam < ApplicationRecord
  include ContributesToPatientTeams

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited associated_with: :team
  has_associated_audits

  belongs_to :team

  has_many :locations

  has_many :community_clinics, -> { community_clinic }, class_name: "Location"
  has_many :schools, -> { school }, class_name: "Location"

  normalizes :email, with: EmailAddressNormaliser.new
  normalizes :phone, with: PhoneNumberNormaliser.new

  validates :name, presence: true, uniqueness: { scope: :team }
  validates :email, notify_safe_email: true
  validates :phone, presence: true, phone: true
end
