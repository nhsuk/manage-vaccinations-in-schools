# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :bigint           not null, primary key
#  current_sign_in_at          :datetime
#  current_sign_in_ip          :string
#  email                       :string
#  encrypted_password          :string           default(""), not null
#  fallback_role               :integer          default("nurse"), not null
#  family_name                 :string           not null
#  given_name                  :string           not null
#  last_sign_in_at             :datetime
#  last_sign_in_ip             :string
#  provider                    :string
#  remember_created_at         :datetime
#  reporting_api_session_token :string
#  session_token               :string
#  sign_in_count               :integer          default(0), not null
#  uid                         :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_users_on_email                        (email) UNIQUE
#  index_users_on_provider_and_uid             (provider,uid) UNIQUE
#  index_users_on_reporting_api_session_token  (reporting_api_session_token) UNIQUE
#
class User < ApplicationRecord
  include FullNameConcern

  attr_accessor :cis2_info

  if Settings.cis2.enabled
    devise :omniauthable, :trackable, :timeoutable, omniauth_providers: %i[cis2]
  else
    devise :database_authenticatable, :trackable, :timeoutable
  end

  has_and_belongs_to_many :teams
  has_many :organisations, -> { distinct }, through: :teams

  has_many :programmes, through: :teams

  has_one :reporting_api_one_time_token,
          class_name: "ReportingAPI::OneTimeToken"

  encrypts :email, deterministic: true
  encrypts :family_name, :given_name

  normalizes :email, with: EmailAddressNormaliser.new

  validates :family_name, :given_name, presence: true, length: { maximum: 255 }

  validates :email,
            uniqueness: true,
            notify_safe_email: true,
            if: :requires_email_and_password?

  validates :password,
            presence: true,
            confirmation: true,
            length: {
              within: 6..128
            },
            if: :requires_email_and_password?

  scope :recently_active,
        -> { where(last_sign_in_at: 1.week.ago..Time.current) }

  enum :fallback_role,
       { nurse: 0, admin: 1, superuser: 2, healthcare_assistant: 3 },
       prefix: true

  delegate :fhir_practitioner, to: :fhir_mapper

  def self.find_or_create_from_cis2_oidc(userinfo, teams)
    user =
      User.find_or_initialize_by(
        provider: userinfo[:provider],
        uid: userinfo[:uid]
      )

    raw_info = userinfo[:extra][:raw_info]

    user.assign_attributes(
      raw_info.slice(:email, :family_name, :given_name).to_h
    )
    user.session_token = raw_info[:sid].presence || Devise.friendly_token

    ActiveRecord::Base.transaction do
      user.save!

      teams.each { |team| user.teams << team unless user.teams.include?(team) }

      user
    end
  end

  def requires_email_and_password?
    provider.blank? || uid.blank?
  end

  def selected_organisation = cis2_info.organisation

  def selected_team = cis2_info.team

  def role_name
    cis2_info.role_name if cis2_enabled?
  end

  def is_admin?
    if cis2_enabled?
      cis2_info.is_admin?
    else
      fallback_role_admin? || fallback_role_superuser?
    end
  end

  def is_nurse?
    cis2_enabled? ? cis2_info.is_nurse? : fallback_role_nurse?
  end

  def is_superuser?
    cis2_enabled? ? cis2_info.is_superuser? : fallback_role_superuser?
  end

  def is_healthcare_assistant?
    if cis2_enabled?
      cis2_info.is_healthcare_assistant?
    else
      fallback_role_healthcare_assistant?
    end
  end

  private

  def cis2_enabled? = Settings.cis2.enabled

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::User.new(self)
end
