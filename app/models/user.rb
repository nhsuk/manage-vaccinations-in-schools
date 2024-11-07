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

  attr_accessor :cis2_info

  if Settings.cis2.enabled
    devise :omniauthable, :trackable, :timeoutable, omniauth_providers: %i[cis2]
  else
    devise :database_authenticatable, :trackable, :timeoutable
  end

  has_and_belongs_to_many :organisations

  has_many :programmes, through: :organisations

  encrypts :email, deterministic: true
  encrypts :family_name, :given_name

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

  enum :fallback_role, { nurse: 0, admin: 1 }, prefix: true

  def selected_organisation
    @selected_organisation ||=
      if Settings.cis2.enabled
        Organisation.find_by(ods_code: cis2_info.dig("selected_org", "code"))
      else
        organisations.first
      end
  end

  def requires_email_and_password?
    provider.blank? || uid.blank?
  end

  def self.find_or_create_from_cis2_oidc(userinfo)
    user =
      User.find_or_initialize_by(
        provider: userinfo[:provider],
        uid: userinfo[:uid]
      )

    user.family_name = userinfo[:extra][:raw_info][:family_name]
    user.given_name = userinfo[:extra][:raw_info][:given_name]
    user.email = userinfo[:info][:email]
    user.session_token =
      userinfo[:extra][:raw_info][:sid].presence || Devise.friendly_token

    user.tap(&:save!)
  end

  def is_admin?
    return fallback_role_admin? unless Settings.cis2.enabled

    selected_role = cis2_info.dig("selected_role", "code")
    selected_role.ends_with? "R8006"
  end

  def role_description
    if is_admin?
      "Administrator"
    elsif is_nurse?
      "Nurse"
    end
  end

  def is_nurse?
    return fallback_role_nurse? unless Settings.cis2.enabled

    selected_role = cis2_info.dig("selected_role", "code")
    selected_role.ends_with? "R8001"
  end
end
