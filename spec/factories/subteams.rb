# frozen_string_literal: true

# == Schema Information
#
# Table name: subteams
#
#  id                 :bigint           not null, primary key
#  email              :string           not null
#  name               :string           not null
#  phone              :string           not null
#  phone_instructions :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  reply_to_id        :uuid
#  team_id            :bigint           not null
#
# Indexes
#
#  index_subteams_on_team_id_and_name  (team_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :subteam do
    transient { sequence(:identifier) }

    team

    name { "SAIS Subteam #{identifier}" }
    email { "sais-subteam-#{identifier}@example.com" }
    phone { "01234 567890" }
  end
end
