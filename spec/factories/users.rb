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
FactoryBot.define do
  factory :user,
          aliases: %i[nurse assessor created_by performed_by uploaded_by] do
    transient do
      selected_organisation { organisations.first }
      selected_role_code { "S8000:G8000:R8001" }
      selected_role_name { "Nurse Access Role" }

      cis2_info_hash do
        {
          "selected_org" => {
            "name" => selected_organisation.name,
            "code" => selected_organisation.ods_code
          },
          "selected_role" => {
            "name" => selected_role_name,
            "code" => selected_role_code
          }
        }
      end
    end

    sequence(:family_name) { |n| "User #{n}" }
    given_name { "Test" }

    sequence(:email) { |n| "nurse-#{n}@example.com" }
    sequence(:organisations) { [Organisation.first || create(:organisation)] }
    # It would normally be reasonable to expect to set a password here. However,
    # when cis2 is enabled Devise does not create a 'password=' method for us,
    # so we can't include the following setter. If you have a need to test users
    # with passwords you'll have to do something tricky like either load the
    # User model with cis2 disabled to trigger the Devise code that adds that
    # method, or stub out the methods yourself. Good luck, meta force be with
    # you.
    #
    # password { "power overwhelming!" }

    provider { Settings.cis2.enabled ? "cis2" : nil }
    sequence(:uid) { Settings.cis2.enabled ? _1.to_s : nil }
    cis2_info { Settings.cis2.enabled ? cis2_info_hash : nil }

    trait :cis2 do
      provider { "cis2" }
      sequence(:uid, &:to_s)
      cis2_info { cis2_info_hash }
    end

    factory :admin do
      transient do
        selected_role_code { "S8000:G8001:R8006" }
        selected_role_name { "Medical Secretary Access Role" }
      end
      sequence(:email) { |n| "admin-#{n}@example.com" }
    end

    trait :signed_in do
      current_sign_in_at { Time.current }
      current_sign_in_ip { "127.0.0.1" }
    end
  end
end
