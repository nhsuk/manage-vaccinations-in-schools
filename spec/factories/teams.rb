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
    sequence(:name) { |n| "Team #{n}" }
    sequence(:email) { |n| "team-#{n}@example.com" }
    ods_code { "U#{rand(10_000..99_999)}" }
    privacy_policy_url { "https://example.com/privacy" }
    sequence(:reply_to_id) { |n| "reply-to-id-team-#{n}" }
  end
end
