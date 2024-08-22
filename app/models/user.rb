# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  family_name            :string           not null
#  given_name             :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  provider               :string
#  registration           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  uid                    :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_provider_and_uid      (provider,uid)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
  devise :database_authenticatable,
         :lockable,
         :trackable,
         :timeoutable,
         :recoverable,
         :validatable,
         :omniauthable,
         omniauth_providers: %i[cis2]

  devise :pwned_password unless Rails.env.test?

  has_and_belongs_to_many :teams

  encrypts :email, deterministic: true
  encrypts :full_name, :family_name, :given_name

  validates :family_name, :given_name, presence: true, length: { maximum: 255 }

  validates :registration, length: { maximum: 255 }
  validates :email,
            presence: true,
            length: {
              maximum: 255
            },
            uniqueness: true,
            notify_safe_email: true

  scope :recently_active,
        -> { where(last_sign_in_at: 1.week.ago..Time.current) }

  def full_name
    [given_name, family_name].join(" ")
  end

  def team
    # TODO: Update the app to properly support multiple teams per user
    teams.first
  end

  def self.find_or_create_user_from_cis2_oidc(userinfo)
    user =
      User.find_or_initialize_by(
        provider: userinfo[:provider],
        uid: userinfo[:uid]
      )

    user.family_name = userinfo[:extra][:raw_info][:family_name]
    user.given_name = userinfo[:extra][:raw_info][:given_name]
    user.email = userinfo[:info][:email]
    user.password = Devise.friendly_token if user.new_record?

    user.tap(&:save!)
  end
end
