# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                 :bigint           not null, primary key
#  email              :string           not null
#  name               :string           not null
#  phone              :string           not null
#  phone_instructions :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  organisation_id    :bigint           not null
#  reply_to_id        :uuid
#
# Indexes
#
#  index_teams_on_organisation_id_and_name  (organisation_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
FactoryBot.define do
  factory :team do
    transient { sequence(:identifier) }

    organisation

    name { "SAIS Team #{identifier}" }
    email { "sais-team-#{identifier}@example.com" }
    phone { "01234 567890" }
  end
end
