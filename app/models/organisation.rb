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
#  phone_instructions            :string
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

  audited
  has_associated_audits

  has_many :batches
  has_many :cohort_imports
  has_many :consent_forms
  has_many :consents
  has_many :immunisation_records
  has_many :locations
  has_many :organisation_programmes,
           -> { joins(:programme).order(:"programmes.type") }
  has_many :sessions
  has_many :teams

  has_many :community_clinics, through: :teams
  has_many :locations, through: :teams
  has_many :patient_sessions, through: :sessions
  has_many :patients, through: :patient_sessions
  has_many :programmes, through: :organisation_programmes
  has_many :schools, through: :teams
  has_many :vaccination_records, through: :sessions
  has_many :vaccines, through: :programmes

  has_many :location_programme_year_groups,
           -> { where(programme: it.programmes) },
           through: :locations,
           source: :programme_year_groups,
           class_name: "Location::ProgrammeYearGroup"

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

  delegate :fhir_reference, to: :fhir_mapper

  class << self
    delegate :fhir_reference, to: FHIRMapper::Organisation
  end

  def year_groups
    @year_groups ||= location_programme_year_groups.pluck_year_groups
  end

  def generic_clinic_session
    academic_year = AcademicYear.current
    location = locations.generic_clinic.first

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

  private

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::Organisation.new(self)
end
