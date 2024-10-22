# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                            :bigint           not null, primary key
#  days_before_consent_reminders :integer          default(7), not null
#  days_before_consent_requests  :integer          default(21), not null
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
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#
FactoryBot.define do
  factory :team do
    transient { sequence(:identifier) { _1 } }

    name { "SAIS Team #{identifier}" }
    email { "sais-team-#{identifier}@example.com" }
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
          **{
            teams: [instance],
            email: nurse_email,
            password: nurse_password
          }.compact
        )
      end
    end

    trait :with_generic_clinic do
      after(:create) do |team, _evaluator|
        create(:location, :generic_clinic, team:)
      end
    end
  end
end
