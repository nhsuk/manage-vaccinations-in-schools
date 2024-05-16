# == Schema Information
#
# Table name: teams
#
#  id                 :bigint           not null, primary key
#  email              :string
#  name               :text             not null
#  ods_code           :string
#  phone              :string
#  privacy_policy_url :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  reply_to_id        :string
#
# Indexes
#
#  index_teams_on_name  (name) UNIQUE
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
    reply_to_id { "reply-to-id-team-#{identifier}" }

    trait :with_one_nurse do
      transient do
        nurse_email { nil }
        nurse_password { nil }
      end

      after(:create) do |team, evaluator|
        options = {
          teams: [team],
          email: evaluator.nurse_email,
          password: evaluator.nurse_password
        }.compact
        create(:user, **options)
      end
    end

    trait :with_one_location do
      after(:create) { |team| create(:location, team:) }
    end
  end
end
