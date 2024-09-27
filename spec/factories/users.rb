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
FactoryBot.define do
  factory :user, aliases: %i[assessor created_by performed_by uploaded_by] do
    sequence(:family_name) { |n| "User #{n}" }
    given_name { "Test" }

    sequence(:email) { |n| "test-#{n}@example.com" }
    sequence(:teams) { [Team.first || create(:team)] }
    password { "power overwhelming!" } # avoid a password that was found in a data breach
    registration { "SW608658 (HCPC)" }
  end
end
