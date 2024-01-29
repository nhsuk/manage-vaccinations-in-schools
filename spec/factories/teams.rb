# == Schema Information
#
# Table name: teams
#
#  id         :bigint           not null, primary key
#  email      :string
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_teams_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
  end
end
