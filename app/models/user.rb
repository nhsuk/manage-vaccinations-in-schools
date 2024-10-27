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
#  family_name         :string           not null
#  given_name          :string           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  provider            :string
#  remember_created_at :datetime
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

  has_and_belongs_to_many :teams

  has_many :programmes, through: :teams

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

  def selected_team
    if Settings.cis2.enabled
      Team.find_by(ods_code: cis2_info.dig("selected_org", "code"))
    else
      teams.first
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

    user.tap(&:save!)
  end

  def is_admin?
    return email.include?("admin") unless Settings.cis2.enabled

    selected_role = cis2_info.dig("selected_role", "code")
    selected_role.ends_with? "R8006"
  end

  def is_nurse?
    return email.include?("nurse") unless Settings.cis2.enabled

    selected_role = cis2_info.dig("selected_role", "code")
    selected_role.ends_with? "R8001"
  end
end
