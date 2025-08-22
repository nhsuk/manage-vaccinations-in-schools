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
#  fallback_role               :integer
#  family_name                 :string           not null
#  given_name                  :string           not null
#  last_sign_in_at             :datetime
#  last_sign_in_ip             :string
#  provider                    :string
#  remember_created_at         :datetime
#  reporting_api_session_token :string
#  session_token               :string
#  show_in_suppliers           :boolean          default(FALSE), not null
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
      team { Team.includes(:organisation).first || create(:team) }

      role_code { CIS2Info::NURSE_ROLE }
      role_workgroups { [] }
      activity_codes { [] }

      cis2_info_hash do
        {
          "organisation_code" => team.organisation.ods_code,
          "organisation_name" => team.name,
          "role_code" => role_code,
          "activity_codes" => activity_codes,
          "team_workgroup" => team.workgroup,
          "workgroups" => role_workgroups + [team.workgroup]
        }
      end
    end

    sequence(:email) { |n| "nurse-#{n}@example.com" }
    fallback_role { :nurse }

    given_name { "Test" }
    family_name { "User" }

    teams { [team] }

    # Don't set a password as this interferes with CIS2.
    # password { "power overwhelming!" }

    provider { Settings.cis2.enabled ? "cis2" : nil }
    sequence(:uid) { Settings.cis2.enabled ? it.to_s : nil }

    cis2_info do
      if Settings.cis2.enabled
        CIS2Info.new(request_session: { "cis2_info" => cis2_info_hash })
      end
    end

    trait :admin do
      sequence(:email) { |n| "admin-#{n}@example.com" }
      role_code { CIS2Info::ADMIN_ROLE }
      fallback_role { :admin }
    end

    trait :superuser do
      sequence(:email) { |n| "superuser-#{n}@example.com" }
      role_workgroups { [CIS2Info::SUPERUSER_WORKGROUP] }
      fallback_role { :superuser }
    end

    trait :healthcare_assistant do
      sequence(:email) { |n| "healthcare-assistant-#{n}@example.com" }
      role_code { CIS2Info::ADMIN_ROLE }
      activity_codes do
        [CIS2Info::PERSONAL_MEDICATION_ADMINISTRATION_ACTIVITY_CODE]
      end
      fallback_role { :healthcare_assistant }
    end

    trait :signed_in do
      current_sign_in_at { Time.current }
      current_sign_in_ip { "127.0.0.1" }
    end
  end

  factory :admin, parent: :user, traits: %i[admin]
  factory :healthcare_assistant, parent: :user, traits: %i[healthcare_assistant]
  factory :superuser, parent: :user, traits: %i[superuser]
end
