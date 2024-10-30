# frozen_string_literal: true

# == Schema Information
#
# Table name: organisations
#
#  id                            :bigint           not null, primary key
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
#  days_before_invitations       :integer          default(21), not null
#  email                         :string
#  name                          :text             not null
#  ods_code                      :string           not null
#  phone                         :string
#  privacy_policy_url            :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reply_to_id                   :uuid
#
# Indexes
#
#  index_organisations_on_name      (name) UNIQUE
#  index_organisations_on_ods_code  (ods_code) UNIQUE
#
FactoryBot.define do
  factory :organisation do
    transient { sequence(:identifier) { _1 } }

    name { "SAIS Organisation #{identifier}" }
    email { "sais-organisation-#{identifier}@example.com" }
    phone { "01234 567890" }
    ods_code { "U#{identifier}" }
    privacy_policy_url { "https://example.com/privacy" }

    trait :with_one_nurse do
      transient do
        nurse_email { nil }
        nurse_password { nil }
      end

      users do
        create_list(
          :user,
          1,
          **{ organisations: [instance], email: nurse_email }.compact
        )
      end
    end

    trait :with_one_admin do
      transient { admin_email { "admin.hope@example.com" } }

      users do
        create_list(:user, 1, organisations: [instance], email: admin_email)
      end
    end

    trait :with_generic_clinic do
      after(:create) do |organisation, _evaluator|
        create(:location, :generic_clinic, team: organisation.generic_team)
      end
    end
  end
end
