# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id                            :bigint           not null, primary key
#  careplus_venue_code           :string           not null
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  ods_code                      :string           not null
#  phone                         :string
#  privacy_notice_url            :string           not null
#  privacy_policy_url            :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_organisations_on_name      (name) UNIQUE
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#
class Organisation < ApplicationRecord
  include ODSCodeConcern

  has_many :batches
  has_many :cohort_imports
  has_many :consent_forms
  has_many :consents
  has_many :immunisation_records
  has_many :locations
  has_many :organisation_programmes
  has_many :patients
  has_many :sessions
  has_many :teams

  has_many :community_clinics, through: :teams
  has_many :locations, through: :teams
  has_many :patient_sessions, through: :sessions
  has_many :programmes, through: :organisation_programmes
  has_many :schools, through: :teams
  has_many :vaccines, through: :programmes

  has_and_belongs_to_many :users

  normalizes :email, with: EmailAddressNormaliser.new
  normalizes :phone, with: PhoneNumberNormaliser.new

  validates :careplus_venue_code, presence: true
  validates :email, notify_safe_email: true
  validates :name, presence: true, uniqueness: true
  validates :ods_code, presence: true, uniqueness: true
  validates :phone, presence: true, phone: true
  validates :privacy_notice_url, presence: true
  validates :privacy_policy_url, presence: true

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def generic_team
    teams.create_with(email:, phone:).find_or_create_by!(name:)
  end

  def generic_clinic
    locations.find_by(ods_code:, type: :generic_clinic) ||
      Location.create!(
        name: "Community clinics",
        team: generic_team,
        ods_code:,
        type: :generic_clinic
      )
  end

  def generic_clinic_session
    academic_year = Date.current.academic_year
    location = generic_clinic

    sessions
      .includes(:location, :programmes, :session_dates)
      .create_with(programmes:)
      .find_or_create_by!(academic_year:, location:)
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
