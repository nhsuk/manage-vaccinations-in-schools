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
FactoryBot.define do
  factory :user,
          aliases: %i[
            nurse
            assessor
            created_by
            recorded_by
            performed_by
            uploaded_by
          ] do
    transient do
      organisation { Organisation.first || create(:organisation) }

      selected_role_code { "S8000:G8000:R8001" }
      selected_role_name { "Nurse Access Role" }
      selected_role_workgroups { %w[schoolagedimmunisations] }

      cis2_info_hash do
        {
          "selected_org" => {
            "name" => organisation.name,
            "code" => organisation.ods_code
          },
          "selected_role" => {
            "name" => selected_role_name,
            "code" => selected_role_code,
            "workgroups" => selected_role_workgroups
          }
        }
      end
    end

    sequence(:email) { |n| "nurse-#{n}@example.com" }
    fallback_role { :nurse }

    given_name { "Test" }
    family_name { "User" }

    organisations { [organisation] }

    # Don't set a password as this interferes with CIS2.
    # password { "power overwhelming!" }

    provider { Settings.cis2.enabled ? "cis2" : nil }
    sequence(:uid) { Settings.cis2.enabled ? _1.to_s : nil }
    cis2_info { Settings.cis2.enabled ? cis2_info_hash : nil }

    trait :admin do
      selected_role_code { "S8000:G8001:R8006" }
      selected_role_name { "Medical Secretary Access Role" }
      sequence(:email) { |n| "admin-#{n}@example.com" }
      fallback_role { :admin }
    end

    trait :superuser do
      selected_role_workgroups { %w[schoolagedimmunisations mavissuperusers] }
      fallback_role { :superuser }
    end

    trait :signed_in do
      current_sign_in_at { Time.current }
      current_sign_in_ip { "127.0.0.1" }
    end
  end

  factory :admin, parent: :user, traits: %i[admin]
end
