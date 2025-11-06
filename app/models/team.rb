# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :bigint           not null, primary key
#  careplus_venue_code           :string           not null
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  phone                         :string
#  phone_instructions            :string
#  privacy_notice_url            :string           not null
#  privacy_policy_url            :string           not null
#  type                          :integer          not null
#  workgroup                     :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  organisation_id               :bigint           not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_teams_on_name             (name) UNIQUE
#  index_teams_on_organisation_id  (organisation_id)
#  index_teams_on_workgroup        (workgroup) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
class Team < ApplicationRecord
  include ContributesToPatientTeams
  include DaysBeforeToWeeksBefore
  include HasLocationProgrammeYearGroups

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  audited associated_with: :organisation
  has_associated_audits

  self.inheritance_column = nil

  belongs_to :organisation

  has_many :archive_reasons
  has_many :batches
  has_many :cohort_imports
  has_many :consent_forms
  has_many :consents
  has_many :locations
  has_many :patient_specific_directions
  has_many :sessions
  has_many :subteams
  has_many :team_programmes, -> { joins(:programme).order(:"programmes.type") }
  has_many :patient_teams

  has_many :patients, through: :patient_teams
  has_many :community_clinics, through: :subteams
  has_many :locations, through: :subteams
  has_many :programmes, through: :team_programmes
  has_many :schools, through: :subteams
  has_many :vaccination_records, through: :sessions
  has_many :vaccines, through: :programmes

  has_many :location_year_groups, through: :locations
  has_many :location_programme_year_groups,
           -> { includes(:location_year_group) },
           through: :location_year_groups

  has_and_belongs_to_many :users

  normalizes :email, with: EmailAddressNormaliser.new
  normalizes :phone, with: PhoneNumberNormaliser.new

  enum :type,
       { poc_only: 0, upload_only: 1, poc_with_legacy_upload: 2 },
       validate: true,
       prefix: true

  validates :careplus_venue_code, presence: true
  validates :email, notify_safe_email: true
  validates :name, presence: true, uniqueness: true
  validates :phone, presence: true, phone: true
  validates :privacy_notice_url, presence: true
  validates :privacy_policy_url, presence: true
  validates :workgroup, presence: true, uniqueness: true

  def patients
    Patient.joins_sessions.where(sessions: { team_id: id })
  end

  def year_groups(academic_year: nil)
    academic_year ||= AcademicYear.pending
    location_programme_year_groups
      .joins(:location_year_group)
      .where(location_year_group: { academic_year: })
      .pluck_year_groups
  end

  def generic_clinic = locations.generic_clinic.first

  def generic_clinic_session(academic_year:)
    sessions
      .includes(
        :location,
        :location_programme_year_groups,
        :programmes,
        :session_dates
      )
      .create_with(programmes:)
      .find_or_create_by!(academic_year:, location: generic_clinic)
  end

  def has_upload_access_only?
    Flipper.enabled?(:bulk_upload) && type_upload_only?
  end

  def has_poc_access?
    return true unless Flipper.enabled?(:bulk_upload)

    type_poc_only? || type_poc_with_legacy_upload?
  end
end
