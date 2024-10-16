# frozen_string_literal: true

# == Schema Information
#
# Table name: batches
#
#  id          :bigint           not null, primary key
#  archived_at :datetime
#  expiry      :date             not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  team_id     :bigint           not null
#  vaccine_id  :bigint           not null
#
# Indexes
#
#  index_batches_on_team_id                                     (team_id)
#  index_batches_on_team_id_and_name_and_expiry_and_vaccine_id  (team_id,name,expiry,vaccine_id) UNIQUE
#  index_batches_on_vaccine_id                                  (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#

FactoryBot.define do
  factory :batch do
    transient { prefix { Faker::Alphanumeric.alpha(number: 2).upcase } }

    team
    vaccine

    name { "#{prefix}#{Faker::Number.number(digits: 4)}" }
    expiry { Faker::Time.forward(days: 50) }

    trait :archived do
      archived_at { Time.current }
    end
  end
end
