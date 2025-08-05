# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  email               :string
#  encrypted_password  :string           default(""), not null
#  fallback_role       :integer          default("nurse"), not null
#  family_name         :string           not null
#  given_name          :string           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  provider            :string
#  remember_created_at :datetime
#  session_token       :string
#  sign_in_count       :integer          default(0), not null
#  uid                 :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_email             (email) UNIQUE
#  index_users_on_provider_and_uid  (provider,uid) UNIQUE
#
class User < ApplicationRecord
  include FullNameConcern

  CIS2_NURSE_ROLE = "S8000:G8000:R8001"
  CIS2_ADMIN_ROLE = "S8000:G8001:R8006"

  CIS2_WORKGROUP = "schoolagedimmunisations"

  attr_accessor :cis2_info

  if Settings.cis2.enabled
    devise :omniauthable, :trackable, :timeoutable, omniauth_providers: %i[cis2]
  else
    devise :database_authenticatable, :trackable, :timeoutable
  end

  has_and_belongs_to_many :teams

  has_many :programmes, through: :teams

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

  def selected_organisation
    @selected_organisation ||=
      if cis2_info.present?
        Organisation.find_by(ods_code: cis2_info.dig("selected_org", "code"))
      end
  end

  def selected_team
    # TODO: Select the right team based on the user's workgroup.
    @selected_team ||=
      Team.includes(:location_programme_year_groups, :programmes).find_by(
        organisation: selected_organisation
      )
  end

  def requires_email_and_password?
    provider.blank? || uid.blank?
  end

  def is_admin?
    if Settings.cis2.enabled
      cis2_info.dig("selected_role", "code")&.ends_with?("R8006")
    else
      fallback_role_admin? || fallback_role_superuser?
    end
  end

  def is_nurse?
    return fallback_role_nurse? unless Settings.cis2.enabled

    cis2_info.dig("selected_role", "code")&.ends_with?("R8001")
  end

  def is_superuser?
    return fallback_role_superuser? unless Settings.cis2.enabled

    cis2_info.dig("selected_role", "workgroups")&.include?("mavissuperusers") ||
      false
  end

  def is_healthcare_assistant?
    # TODO: How do we determine this from CIS2?
    return false if Settings.cis2.enabled

    fallback_role_healthcare_assistant?
  end

  def role_description
    role =
      if is_admin?
        "Administrator"
      elsif is_nurse?
        "Nurse"
      else
        "Unknown"
      end

    if is_healthcare_assistant? && is_superuser?
      "#{role} (Healthcare assistant and superuser)"
    elsif is_healthcare_assistant?
      "#{role} (Healthcare assistant)"
    elsif is_superuser?
      "#{role} (Superuser)"
    else
      role
    end
  end

  private

  def fhir_mapper = @fhir_mapper ||= FHIRMapper::User.new(self)
end
