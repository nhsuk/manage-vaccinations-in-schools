# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  email               :string           default(""), not null
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
FactoryBot.define do
  factory :user, aliases: %i[assessor created_by performed_by uploaded_by] do
    sequence(:family_name) { |n| "User #{n}" }
    given_name { "Test" }

    sequence(:email) { |n| "test-#{n}@example.com" }
    sequence(:teams) { [Team.first || create(:team)] }
    password { "power overwhelming!" }

    trait :cis2 do
      provider { "cis2" }
      sequence(:uid, &:to_s)
      password { nil }
    end

    trait :signed_in do
      current_sign_in_at { Time.current }
      current_sign_in_ip { "127.0.0.1" }
    end
  end
end
