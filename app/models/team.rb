# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :bigint           not null, primary key
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  ods_code                      :string           not null
#  phone                         :string
#  privacy_policy_url            :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#
class Team < ApplicationRecord
  include ODSCodeConcern

  has_many :batches
  has_many :clinics, -> { clinic }, class_name: "Location"
  has_many :cohort_imports
  has_many :cohorts
  has_many :consent_forms
  has_many :consents
  has_many :locations
  has_many :schools, -> { school }, class_name: "Location"
  has_many :sessions
  has_many :team_programmes

  has_many :patient_sessions, through: :sessions
  has_many :programmes, through: :team_programmes
  has_many :vaccination_records, through: :patient_sessions

  has_and_belongs_to_many :users

  validates :email, notify_safe_email: true
  validates :name, presence: true, uniqueness: true
  validates :ods_code, presence: true
  validates :phone, presence: true, phone: true

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def generic_clinic
    locations.create_with(name: "Community clinics").find_or_create_by!(
      ods_code:,
      type: :generic_clinic
    )
  end

  def generic_clinic_session
    academic_year = Date.current.academic_year
    location = generic_clinic

    sessions.create_with(programmes:).find_or_create_by!(
      academic_year:,
      location:
    )
  end

  def weeks_before_consent_reminders
    (days_before_consent_reminders / 7).to_i
  end

  def weeks_before_consent_reminders=(value)
    self.days_before_consent_reminders = value * 7
  end

  def weeks_before_consent_requests
    (days_before_consent_requests / 7).to_i
  end

  def weeks_before_consent_requests=(value)
    self.days_before_consent_requests = value * 7
  end

  def weeks_before_invitations
    (days_before_invitations / 7).to_i
  end

  def weeks_before_invitations=(value)
    self.days_before_invitations = value * 7
  end
end
