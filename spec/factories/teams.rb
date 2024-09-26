# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                                                :bigint           not null, primary key
#  days_between_consent_requests_and_first_reminders :integer          default(7), not null
#  days_between_first_session_and_consent_requests   :integer          default(21), not null
#  days_between_subsequent_consent_reminders         :integer          default(7), not null
#  email                                             :string
#  maximum_number_of_consent_reminders               :integer          default(4), not null
#  name                                              :text             not null
#  ods_code                                          :string           not null
#  phone                                             :string
#  privacy_policy_url                                :string
#  send_updates_by_text                              :boolean          default(FALSE), not null
#  created_at                                        :datetime         not null
#  updated_at                                        :datetime         not null
#  reply_to_id                                       :uuid
#
# Indexes
#
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#
FactoryBot.define do
  factory :team do
    transient do
      random { Random.new }
      sequence(:identifier) { _1 }
    end

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
  end
end
