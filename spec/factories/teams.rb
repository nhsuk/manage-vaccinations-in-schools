# == Schema Information
#
# Table name: teams
#
#  id                 :bigint           not null, primary key
#  email              :string
#  name               :text             not null
#  ods_code           :string
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
      identifier { random.rand(1..10_000) }
    end

    name { "Team #{identifier}" }
    email { "team-#{identifier}@example.com" }
    ods_code { "U#{identifier}" }
    privacy_policy_url { "https://example.com/privacy" }
    reply_to_id { "reply-to-id-team-#{identifier}" }
  end
end
